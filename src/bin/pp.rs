//! pipeprogress binary
//!
//! ## Overview
//!
//! pipeprogress is a command line utility for visualizing progress
//! for long pipe operations.
//!
//! ## Usage
//!
//! Usage information for the ```pipeprogress``` application is available
//! by running ```pipeprogress --help```.
//

use crossbeam::channel::{bounded, unbounded};
use pipeprogress::{args::Args, read, stats, write};
use std::io::Result;
use std::thread;

fn main() -> Result<()> {
    // Parse the command line arguments
    let args = Args::parse();

    // Destructure Args back into individual vars
    let Args {
        infile,
        outfile,
        silent,
    } = args;

    // Use unbounded crossbeam channel for stats but bounded for write
    let (stats_tx, stats_rx) = unbounded();
    let (write_tx, write_rx) = bounded(1024);

    // Convert infile and outfile to Option<&str>
    let read_handle = thread::spawn(move || read::read_loop(infile.as_deref(), stats_tx, write_tx));
    let stats_handle = thread::spawn(move || stats::stats_loop(silent, stats_rx));
    let write_handle = thread::spawn(move || write::write_loop(outfile.as_deref(), write_rx));

    // Crash the entire program if any threads have crashed
    let read_io_result = read_handle.join().unwrap();
    let stats_io_result = stats_handle.join().unwrap();
    let write_io_result = write_handle.join().unwrap();

    // Return any error if any of the threads returned an error
    read_io_result?;
    stats_io_result?;
    write_io_result?;

    Ok(())
}
