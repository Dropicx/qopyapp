use qopyapp::{PeerDiscovery, DiscoveryConfig, get_network_interfaces};
use std::collections::HashMap;
use std::time::Duration;
use tracing::{info, warn, error};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing with more detailed output
    tracing_subscriber::fmt()
        .with_env_filter("debug")
        .init();
    
    // Show available network interfaces
    info!("Available network interfaces:");
    let interfaces = get_network_interfaces().await?;
    for interface in &interfaces {
        if !interface.is_loopback {
            info!("  - {}: {}", interface.name, interface.ip);
        }
    }
    
    // Create configuration for this device
    let mut properties = HashMap::new();
    properties.insert("version".to_string(), "1.0.0".to_string());
    properties.insert("device_type".to_string(), "monitor".to_string());
    properties.insert("capabilities".to_string(), "file_sharing,chat".to_string());
    
    let config = DiscoveryConfig {
        service_type: "_qopyapp._tcp.local.".to_string(),
        service_name: format!("monitor-{}", std::process::id()),
        port: 8080,
        properties,
        discovery_timeout: Duration::from_secs(15),
        announce_interval: Duration::from_secs(30),
    };
    
    // Create and start discovery
    let discovery = PeerDiscovery::new(config)?;
    let mut event_receiver = discovery.subscribe();
    
    discovery.start().await?;
    info!("Network monitoring started");
    
    // Monitor for network changes and peer events
    let _discovery_clone = discovery.clone();
    let monitor_task = tokio::spawn(async move {
        let mut last_peer_count: i32 = 0;
        
        while let Ok(event) = event_receiver.recv().await {
            match event {
                qopyapp::PeerEvent::PeerDiscovered(peer) => {
                    info!("🔍 New peer discovered: {} at {}:{}", 
                          peer.name, peer.ip, peer.port);
                    
                    // Show peer capabilities
                    if let Some(capabilities) = peer.properties.get("capabilities") {
                        info!("   Capabilities: {}", capabilities);
                    }
                    
                    last_peer_count += 1;
                }
                qopyapp::PeerEvent::PeerLost(peer) => {
                    warn!("❌ Peer lost: {}", peer.name);
                    last_peer_count = last_peer_count.saturating_sub(1);
                }
                qopyapp::PeerEvent::ServiceStarted => {
                    info!("✅ Discovery service started");
                }
                qopyapp::PeerEvent::ServiceStopped => {
                    info!("🛑 Discovery service stopped");
                }
                qopyapp::PeerEvent::Error(err) => {
                    error!("💥 Discovery error: {}", err);
                }
            }
        }
    });
    
    // Periodic status updates
    let discovery_status = discovery.clone();
    let status_task = tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(10));
        
        loop {
            interval.tick().await;
            
            let peers = discovery_status.get_peers().await;
            info!("📊 Status: {} peers currently online", peers.len());
            
            if !peers.is_empty() {
                info!("   Active peers:");
                for peer in &peers {
                    info!("     - {} ({}:{})", peer.name, peer.ip, peer.port);
                }
            }
        }
    });
    
    // Run for a specified duration
    let run_duration = Duration::from_secs(60);
    info!("Running network monitor for {:?}...", run_duration);
    
    tokio::select! {
        _ = tokio::time::sleep(run_duration) => {
            info!("Monitoring period completed");
        }
        _ = tokio::signal::ctrl_c() => {
            info!("Received Ctrl+C, stopping...");
        }
    }
    
    // Cleanup
    discovery.stop().await?;
    monitor_task.abort();
    status_task.abort();
    
    info!("Network monitoring stopped");
    Ok(())
}
