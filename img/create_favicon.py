#!/usr/bin/env python3
import struct
import os

def create_ico_from_pngs(png_files, output_file):
    """Create an ICO file from multiple PNG files."""
    # ICO header
    ico_header = struct.pack('<HHH', 0, 1, len(png_files))
    
    # Directory entries and image data
    entries = []
    images = []
    offset = 6 + 16 * len(png_files)  # Header + directory entries
    
    for png_file in png_files:
        with open(png_file, 'rb') as f:
            png_data = f.read()
        
        # Get size from filename (e.g., favicon-16.png -> 16)
        size = int(png_file.split('-')[1].split('.')[0])
        
        # ICO directory entry
        entry = struct.pack('<BBBBHHII',
            size if size < 256 else 0,  # Width (0 = 256)
            size if size < 256 else 0,  # Height (0 = 256)
            0,  # Color palette
            0,  # Reserved
            1,  # Color planes
            32, # Bits per pixel
            len(png_data),  # Image size
            offset  # Image offset
        )
        entries.append(entry)
        images.append(png_data)
        offset += len(png_data)
    
    # Write ICO file
    with open(output_file, 'wb') as f:
        f.write(ico_header)
        for entry in entries:
            f.write(entry)
        for image in images:
            f.write(image)

# Create the ICO file
png_files = ['favicon-16.png', 'favicon-32.png', 'favicon-48.png']
create_ico_from_pngs(png_files, 'favicon.ico')
print("favicon.ico created successfully!")

# Clean up temporary PNG files
for png_file in png_files:
    os.remove(png_file)
print("Temporary PNG files removed.")