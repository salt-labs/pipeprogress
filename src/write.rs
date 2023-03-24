//! Writes the output to file or stdout
//!
//! # Write
//!
//! Writes the output to file or stdout
//!

use crossbeam::channel::Receiver;
use std::fs::File;
use std::io::{self, BufWriter, ErrorKind, Result, Write};

// Update the function signature to accept Option<&str> for outfile
pub fn write_loop(outfile: Option<&str>, write_rx: Receiver<Vec<u8>>) -> Result<()> {
    // write to a file if provided, otherwise send to stdout
    let mut writer: Box<dyn Write> = match outfile {
        Some(path) => Box::new(BufWriter::new(File::create(path)?)),
        None => Box::new(BufWriter::new(io::stdout())),
    };

    loop {
        // receive the vector from stats thread
        let buffer = write_rx.recv().unwrap();

        if buffer.is_empty() {
            break;
        }

        if let Err(e) = writer.write_all(&buffer) {
            if e.kind() == ErrorKind::BrokenPipe {
                // stop the program cleanly
                return Ok(());
            }
            return Err(e);
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crossbeam::channel::unbounded;
    use std::fs::File;
    use std::io::Read;

    #[test]
    fn test_write_loop() -> Result<()> {
        // Set up channels
        let (write_tx, write_rx) = unbounded();

        // Prepare test data
        let test_data = b"Pipe Progress...";
        write_tx.send(test_data.to_vec()).unwrap();
        write_tx.send(Vec::new()).unwrap(); // To signal the end of transmission

        // Test write_loop
        let test_output = "test_output.txt";
        write_loop(Some(test_output), write_rx)?;

        // Read the test output file and compare its content with test_data
        let mut file = File::open(test_output)?;
        let mut received_data = Vec::new();
        file.read_to_end(&mut received_data)?;

        assert_eq!(test_data, received_data.as_slice());

        // Clean up the test output file
        std::fs::remove_file(test_output)?;

        Ok(())
    }
}
