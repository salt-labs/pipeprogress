//! Reads the input from file or stdin
//!
//! # Read
//!
//! Reads the input from file or stdin
//!

use crate::CHUNK_SIZE;

use crossbeam::channel::Sender;
use std::fs::File;
use std::io::{self, BufReader, Read, Result};

// Public function to read the infile or stdin
pub fn read_loop(infile: &str, stats_tx: Sender<usize>, write_tx: Sender<Vec<u8>>) -> Result<()> {
    // Read from a file if provided, otherwise default to stdin
    let mut reader: Box<dyn Read> = if !infile.is_empty() {
        Box::new(BufReader::new(File::open(infile)?))
    } else {
        Box::new(BufReader::new(io::stdin()))
    };

    let mut buffer = [0; CHUNK_SIZE];

    loop {
        // Read a fixed number of bytes from stdin
        let num_read = match reader.read(&mut buffer) {
            Ok(0) => break,  // break on 0 bytes
            Ok(x) => x,      // return the number of bytes
            Err(_) => break, // break on error
        };

        // send this buffer to the stats thread
        let _ = stats_tx.send(num_read);

        // send this buffer to the write thread
        if write_tx.send(Vec::from(&buffer[..num_read])).is_err() {
            break;
        }
    }
    // send an empty buffer to the stats thread
    let _ = stats_tx.send(0);
    let _ = write_tx.send(Vec::new());
    Ok(())
}
