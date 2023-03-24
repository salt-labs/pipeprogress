//! # Timer
//!
//! The stats timer module
//!

use std::time::{Duration, Instant};

/// Data structure for Timer
pub struct Timer {
    pub last_instant: Instant,
    pub delta: Duration,
    pub period: Duration,
    pub countdown: Duration,
    pub ready: bool,
}

/// Implementation for Timer
impl Timer {
    /// Function to create a new timer
    pub fn new() -> Self {
        let now = Instant::now();

        Self {
            last_instant: now,
            delta: Duration::default(), // 0
            period: Duration::from_millis(1000),
            countdown: Duration::default(), // 0
            ready: true,
        }
    }

    /// Function to update an existing timer
    pub fn update(&mut self) {
        let now = Instant::now();

        self.delta = now - self.last_instant;
        self.last_instant = now;
        // Set the timer ready to true on error
        self.countdown = self.countdown.checked_sub(self.delta).unwrap_or_else(|| {
            self.ready = true;
            self.period
        });
    }
}
