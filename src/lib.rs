//! pipeprogress library
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
//!

pub mod args;
pub mod read;
pub mod stats;
pub mod write;

const CHUNK_SIZE: usize = 16 * 1024;
