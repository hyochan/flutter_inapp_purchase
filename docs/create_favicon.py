#!/usr/bin/env python3
from PIL import Image

try:
    # Open the PNG file
    img = Image.open('/Users/hyo/Github/hyochan/flutter_inapp_purchase/docs/static/img/logo.png')
    
    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Create favicon.ico with multiple sizes
    sizes = [(16, 16), (32, 32), (48, 48)]
    favicon_images = [img.resize(size, Image.Resampling.LANCZOS) for size in sizes]
    
    # Save as ICO
    favicon_images[0].save(
        '/Users/hyo/Github/hyochan/flutter_inapp_purchase/docs/static/img/favicon.ico',
        format='ICO',
        sizes=sizes
    )
    
    print('Successfully created favicon.ico')
except ImportError:
    print('PIL/Pillow not available')
except Exception as e:
    print(f'Error: {e}')