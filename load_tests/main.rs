use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use clap::Parser;
use futures::StreamExt;
use indicatif::{ProgressBar, ProgressStyle};
use tokio::sync::Semaphore;
use tokio_tungstenite::connect_async;
use url::Url;

#[derive(Parser, Debug)]
#[clap(about = "WebSocket load tester")]
struct Args {

    concurrent: usize,


    total: usize,


    host: String,


    rate: u64,


    duration: u64,
}

struct Metrics {
    total_connections: AtomicUsize,
    active_connections: AtomicUsize,
    messages_sent: AtomicUsize,
    messages_received: AtomicUsize,
    errors: AtomicUsize,
    total_latency: AtomicUsize,
}

impl Metrics {
    fn new() -> Self {
        Self {
            total_connections: AtomicUsize::new(0),
            active_connections: AtomicUsize::new(0),
            messages_sent: AtomicUsize::new(0),
            messages_received: AtomicUsize::new(0),
            errors: AtomicUsize::new(0),
            total_latency: AtomicUsize::new(0),
        }
    }
}

#[tokio::main]
async fn main() {
    let args = Args::parse();
    let metrics = Arc::new(Metrics::new());
    let semaphore = Arc::new(Semaphore::new(args.concurrent));
    
    let ws_url = format!("ws://{}/socket/websocket", args.host);
    let url = Url::parse(&ws_url).expect("Failed to parse URL");
    
    println!("Connecting to {}", url);
    
    let pb = ProgressBar::new(args.total as u64);
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta})")
        .unwrap());

    let start_time = Instant::now();
    let deadline = start_time + Duration::from_secs(args.duration);
    let mut handles = vec![];

    for id in 0..args.total {
        let permit = semaphore.clone().acquire_owned().await.unwrap();
        let metrics = metrics.clone();
        let url = url.clone();
        let pb = pb.clone();

        let handle = tokio::spawn(async move {
            let _permit = permit;
            match connect_async(&url).await {
                Ok((ws_stream, _)) => {
                    metrics.total_connections.fetch_add(1, Ordering::SeqCst);
                    metrics.active_connections.fetch_add(1, Ordering::SeqCst);
                    
                    let (_, mut read) = ws_stream.split();
                    
                    let message_interval = Duration::from_millis(1000 / args.rate);
                    let mut interval = tokio::time::interval(message_interval);

                    while Instant::now() < deadline {
                        interval.tick().await;
                        
                        let payload = serde_json::json!({
                            "topic": format!("room:{}", id % 100),
                            "event": "ping",
                            "payload": {
                                "time": std::time::SystemTime::now()
                                    .duration_since(std::time::UNIX_EPOCH)
                                    .unwrap()
                                    .as_nanos()
                            }
                        });

                        let start = Instant::now();
                        metrics.messages_sent.fetch_add(1, Ordering::SeqCst);
                        
                        if let Some(msg) = read.next().await {
                            match msg {
                                Ok(_) => {
                                    metrics.messages_received.fetch_add(1, Ordering::SeqCst);
                                    metrics.total_latency.fetch_add(
                                        start.elapsed().as_millis() as usize,
                                        Ordering::SeqCst,
                                    );
                                }
                                Err(_) => {
                                    metrics.errors.fetch_add(1, Ordering::SeqCst);
                                    break;
                                }
                            }
                        }
                    }
                    
                    metrics.active_connections.fetch_sub(1, Ordering::SeqCst);
                }
                Err(_) => {
                    metrics.errors.fetch_add(1, Ordering::SeqCst);
                }
            }
            pb.inc(1);
        });
        handles.push(handle);
    }

    for handle in handles {
        let _ = handle.await;
    }

    pb.finish_with_message("Load test completed");
    
    let elapsed = start_time.elapsed();
    println!("\n=== Results ===");
    println!("Test Duration: {:?}", elapsed);
    println!("Total Connections: {}", metrics.total_connections.load(Ordering::SeqCst));
    println!("Peak Active Connections: {}", metrics.active_connections.load(Ordering::SeqCst));
    println!("Messages Sent: {}", metrics.messages_sent.load(Ordering::SeqCst));
    println!("Messages Received: {}", metrics.messages_received.load(Ordering::SeqCst));
    println!("Errors: {}", metrics.errors.load(Ordering::SeqCst));
    
    let messages_sent = metrics.messages_sent.load(Ordering::SeqCst);
    if messages_sent > 0 {
        let avg_latency = metrics.total_latency.load(Ordering::SeqCst) as f64 / messages_sent as f64;
        println!("Average Latency: {:.2}ms", avg_latency);
        println!("Messages/sec: {:.2}", messages_sent as f64 / elapsed.as_secs_f64());
    }
}
