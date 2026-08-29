import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# Set formatting for a clean, academic, research-paper style
plt.style.use('default')
plt.rcParams['font.family'] = 'serif'
plt.rcParams['axes.grid'] = True
plt.rcParams['grid.linestyle'] = '--'
plt.rcParams['grid.alpha'] = 0.6
plt.rcParams['grid.color'] = '#cccccc'

x_a_vals, y_a_vals = [], []
x_b_vals, y_b_vals = [], []
collision_x, collision_y = None, None

# Read data from the Verilog output file
with open("collision_data.txt", "r") as f:
    for line in f:
        if line.startswith("COLLISION"):
            parts = line.split()
            collision_x = int(parts[1]) / 10.0
            collision_y = int(parts[2]) / 10.0
            break
        
        parts = line.split()
        if len(parts) == 4:
            x_a, y_a, x_b, y_b = [int(p) / 10.0 for p in parts]
            x_a_vals.append(x_a)
            y_a_vals.append(y_a)
            x_b_vals.append(x_b)
            y_b_vals.append(y_b)

# ==========================================
# Academic Plotting Phase
# ==========================================
fig, ax = plt.subplots(figsize=(12, 6.5))

ax.plot(x_a_vals, y_a_vals, label='Interceptor Trajectory (A)', 
        color='blue', linestyle='-', linewidth=1.5)

ax.plot(x_b_vals, y_b_vals, label='Target Trajectory (B)', 
        color='red', linestyle='--', linewidth=1.5)

if collision_x is not None and collision_y is not None:
    # Solid dot for the intersection
    ax.plot(collision_x, collision_y, marker='o', color='black', markersize=8, 
            label='Intersection Point', zorder=5)
    
    bbox_props = dict(boxstyle="square,pad=0.3", fc="white", ec="black", lw=1)
    ax.annotate(f'Intersection\n(X: {collision_x:.1f} m, Y: {collision_y:.1f} m)',
                xy=(collision_x, collision_y),
                xytext=(collision_x - 1400, collision_y + 350), 
                arrowprops=dict(arrowstyle="->", color='black', connectionstyle="arc3"),
                fontsize=10, bbox=bbox_props)

ax.set_title("Dual DSP48A1 Interception Trajectory Analysis", fontsize=14, pad=15)
ax.set_xlabel("Horizontal Distance (m)", fontsize=12)
ax.set_ylabel("Altitude (m)", fontsize=12)

ax.axhline(0, color='black', linewidth=1.2)

# ==========================================
# Precision Grid & Scaling
# ==========================================
# Force X-axis to step by 500
ax.xaxis.set_major_locator(ticker.MultipleLocator(500))
ax.tick_params(axis='x', rotation=45, labelsize=9) 

# Force Y-axis to step by 200 (New Addition)
ax.yaxis.set_major_locator(ticker.MultipleLocator(200))
ax.tick_params(axis='y', labelsize=9) 

# Zoom in perfectly on the trajectories
ax.set_xlim(-200, 8200) 

if y_a_vals and y_b_vals:
    max_altitude = max(max(y_a_vals), max(y_b_vals))
    ax.set_ylim(-100, max_altitude + 500) 

ax.legend(loc='upper right', frameon=True, edgecolor='black', fancybox=False)

plt.tight_layout()
plt.show()