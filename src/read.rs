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

// Update the function signature to accept Option<&str> for infile
pub fn read_loop(
    infile: Option<&str>,
    stats_tx: Sender<usize>,
    write_tx: Sender<Vec<u8>>,
) -> Result<()> {
    // Read from a file if provided, otherwise default to stdin
    let mut reader: Box<dyn Read> = match infile {
        Some(path) => Box::new(BufReader::new(File::open(path)?)),
        None => Box::new(BufReader::new(io::stdin())),
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

#[cfg(test)]
mod tests {
    use super::*;
    use crossbeam::channel::unbounded;
    use std::fs::File;
    use std::io::Write;

    #[test]
    fn test_read_loop() -> Result<()> {
        // Create a test file with some content
        let test_input = "test_input.txt";
        let test_data = "Pipe Progress...";
        let mut file = File::create(test_input)?;
        file.write_all(test_data.as_bytes())?;

        // Set up channels
        let (stats_tx, _stats_rx) = unbounded();
        let (write_tx, write_rx) = unbounded();

        // Test read_loop
        read_loop(Some(test_input), stats_tx.clone(), write_tx.clone())?;

        let mut received_data = Vec::new();
        while let Ok(chunk) = write_rx.recv() {
            if chunk.is_empty() {
                break;
            }
            received_data.extend(chunk);
        }

        assert_eq!(test_data.as_bytes(), received_data.as_slice());

        // Clean up the test file
        std::fs::remove_file(test_input)?;

        Ok(())
    }
}
