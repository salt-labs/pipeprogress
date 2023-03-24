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
