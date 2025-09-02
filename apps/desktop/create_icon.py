#!/usr/bin/env python3
import sys
from PIL import Image, ImageDraw
import io
import math

def create_hub_icon():
    # Create a 512x512 image with transparent background
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors from your mint green scheme
    primary_color = (30, 59, 43, 255)      # #1E3B2B - forest green primary
    accent_color = (107, 144, 128, 255)    # #6B9080 - mint green accent  
    background_color = (245, 251, 248, 255) # #F5FBF8 - light mint background
    
    # Draw background circle
    center = size // 2
    radius = 240
    draw.ellipse([center-radius, center-radius, center+radius, center+radius], 
                fill=background_color, outline=primary_color, width=8)
    
    # Draw Material Design hub icon structure
    # This recreates the atomic/molecular hub structure
    
    # Central node (larger)
    central_radius = 24
    draw.ellipse([center-central_radius, center-central_radius, 
                 center+central_radius, center+central_radius], 
                fill=primary_color, outline=None)
    
    # Outer nodes (smaller) - 6 nodes in a circle
    node_radius = 16
    orbit_radius = 120
    
    nodes = []
    for i in range(6):
        angle = (i * 60) * math.pi / 180  # 60 degrees apart
        x = center + orbit_radius * math.cos(angle)
        y = center + orbit_radius * math.sin(angle)
        nodes.append((x, y))
        
        # Draw node
        draw.ellipse([x-node_radius, y-node_radius, 
                     x+node_radius, y+node_radius], 
                    fill=accent_color, outline=primary_color, width=4)
    
    # Draw connections from center to each outer node
    connection_width = 6
    for x, y in nodes:
        draw.line([center, center, x, y], fill=primary_color, width=connection_width)
    
    # Draw connections between adjacent outer nodes (creating hexagon)
    for i in range(6):
        x1, y1 = nodes[i]
        x2, y2 = nodes[(i + 1) % 6]  # Next node, wrapping around
        draw.line([x1, y1, x2, y2], fill=primary_color, width=connection_width)
    
    # Add some smaller orbital nodes for visual interest
    small_node_radius = 8
    small_orbit_radius = 80
    
    for i in range(3):  # 3 smaller nodes at different angles
        angle = (i * 120 + 30) * math.pi / 180  # Offset by 30 degrees
        x = center + small_orbit_radius * math.cos(angle)
        y = center + small_orbit_radius * math.sin(angle)
        
        draw.ellipse([x-small_node_radius, y-small_node_radius,
                     x+small_node_radius, y+small_node_radius],
                    fill=accent_color, outline=primary_color, width=2)
        
        # Connect to center with thinner lines
        draw.line([center, center, x, y], fill=primary_color, width=3)
    
    return img

def main():
    print("Creating mint green hub icon...")
    
    # Create the main icon
    icon_512 = create_hub_icon()
    
    # Create different sizes for ICO file
    sizes = [16, 32, 48, 64, 128, 256]
    images = []
    
    for size in sizes:
        resized = icon_512.resize((size, size), Image.Resampling.LANCZOS)
        images.append(resized)
    
    # Add the original 512x512
    images.append(icon_512)
    
    # Save as ICO
    ico_path = "windows/runner/resources/app_icon.ico"
    images[0].save(ico_path, format='ICO', sizes=[(img.width, img.height) for img in images])
    
    # Also save PNGs for web
    icon_512.resize((192, 192), Image.Resampling.LANCZOS).save("web/icons/Icon-192.png")
    icon_512.save("web/icons/Icon-512.png")
    icon_512.resize((192, 192), Image.Resampling.LANCZOS).save("web/icons/Icon-maskable-192.png")
    icon_512.save("web/icons/Icon-maskable-512.png")
    icon_512.resize((32, 32), Image.Resampling.LANCZOS).save("web/favicon.png")
    
    print(f"Created app icon: {ico_path}")
    print("Updated web icons")

if __name__ == "__main__":
    main()