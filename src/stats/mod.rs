//! The stats module writes progress to stdout
//!
//! # Stats
//!
//! The stats module writes progress to stdout
//!

mod timer;

//use std::time::{Duration, Instant};
use crossbeam::channel::Receiver;
use crossterm::{
    cursor, execute,
    style::{self, Color, PrintStyledContent, Stylize},
    terminal::{Clear, ClearType},
};
use std::io::{self, Result, Stderr, Write};
use std::time::Instant;
use timer::Timer;

/// Trait for formatting time output adds a `.as_time()` method to `u64`
///
/// # Example
///
/// Here is an example of it's usage
///
/// ```rust
/// use pipeprogress::stats::TimeOutput;
/// assert_eq!(65_u64.as_time(), String::from("0:01:05"))
/// ```
///
pub trait TimeOutput {
    fn as_time(&self) -> String;
}

/// Implementation for TimeOutput
impl TimeOutput for u64 {
    /// Renders the u64 into a time string
    fn as_time(&self) -> String {
        // Get the number of hours and mins remaining
        let (hours, left) = (*self / 3600, *self % 3600);

        // Get the number of mins and secs remaining
        let (minutes, seconds) = (left / 60, left % 60);

        format!(
            "{hours}:{minutes:02}:{seconds:02}",
            hours = hours,
            minutes = minutes,
            seconds = seconds,
        )
    }
}

/// Public function to output the pipe stats
pub fn stats_loop(silent: bool, stats_rx: Receiver<usize>) -> Result<()> {
    let mut total_bytes = 0;
    let time_start = Instant::now();
    let mut timer = Timer::new();
    let mut stderr = io::stderr();

    loop {
        let num_bytes = stats_rx.recv().unwrap();
        timer.update();
        let rps = num_bytes as f64 / timer.delta.as_secs_f64();
        total_bytes += num_bytes;

        if !silent && timer.ready {
            timer.ready = false;
            output_progress(
                &mut stderr,
                total_bytes,
                time_start.elapsed().as_secs().as_time(),
                rps,
            );
        }

        // send consumes the buffer and is left empty, therefore num_bytes is used
        if num_bytes == 0 {
            break;
        }
    }

    if !silent {
        eprintln!();
    }
    Ok(())
}

fn output_progress(stderr: &mut Stderr, bytes: usize, elapsed: String, rate: f64) {
    #![allow(deprecated)]

    // Style bytes in red after converting to a string
    let bytes = style::style(format!("{} ", bytes))
        .stylize()
        .with(Color::Red);

    // Style elapsed time in green
    let elapsed = style::style(elapsed).stylize().with(Color::Green);

    // Style the bps rate in Blue
    let rate = style::style(format!(" [{rate:.0}b/s]", rate = rate))
        .stylize()
        .with(Color::Blue);

    // Output the progress to stderr
    let _ = execute!(
        stderr,
        cursor::MoveToColumn(1),       // Move to position 0 (far left)
        Clear(ClearType::CurrentLine), // Clear the current line
        PrintStyledContent(bytes),     // Display the bytes
        PrintStyledContent(elapsed),   // Display the elapsed time
        PrintStyledContent(rate),      // Display the bps rate
    );

    // Flush stderr to ensure it goes to the screen, however ignore any
    // error incase the binary is not running in a terminal with stderr
    let _ = stderr.flush();
}

#[cfg(test)]
mod tests {
    use super::TimeOutput;

    #[test]
    fn as_time_format() {
        let pairs = vec![
            (5_u64, "0:00:05"),
            (60_u64, "0:01:00"),
            (154_u64, "0:02:34"),
            (3603_u64, "1:00:03"),
        ];
        for (input, output) in pairs {
            assert_eq!(input.as_time().as_str(), output);
        }
    }
}
