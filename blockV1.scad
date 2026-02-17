// ==========================================
// PARAMETRIC NUMBERBLOCKS: S-CURVE LOCK
// "Double Wave" for Maximum Locking Strength
// ==========================================

/* [Global Dimensions] */
block_size = 30.0;
chamfer_size = 1.0;

/* [Connector Settings] */
stud_diam = 16.0;
stud_height = 5.5;
stud_lip = 0.5;

/* [S-Curve Wave Settings] */
enable_snap = true;
wave_amplitude = 0.20;  // Depth of groove & Height of ridge
wave_radius = 2.0;      // "Garden Hose" radius (smoothness)

// Positions relative to the Stud Base (Z=0)
pos_groove_z = 1.5;     // Groove near the base (Proximal)
pos_ridge_z = 3.5;      // Ridge near the top (Distal)

/* [Tolerances] */
tolerance = 0.20;       // Gap between Stud and Socket
socket_depth_clearance = 0.5; 

/* [Face Configuration] */
face_top    = 1; 
face_bottom = 2; 
face_front  = 2; 
face_back   = 1; 
face_left   = 2; 
face_right  = 1; 

$fn = 80;

// ==========================================
// MAIN RENDER
// ==========================================

generate_block();

// ==========================================
// MODULES
// ==========================================

module generate_block() {
    difference() {
        union() {
            chamfered_cube(block_size, chamfer_size);
            
            if (face_top == 1)    orient_to("top")    stud();
            if (face_bottom == 1) orient_to("bottom") stud();
            if (face_front == 1)  orient_to("front")  stud();
            if (face_back == 1)   orient_to("back")   stud();
            if (face_left == 1)   orient_to("left")   stud();
            if (face_right == 1)  orient_to("right")  stud();
        }

        if (face_top == 2)    orient_to("top")    socket();
        if (face_bottom == 2) orient_to("bottom") socket();
        if (face_front == 2)  orient_to("front")  socket();
        if (face_back == 2)   orient_to("back")   socket();
        if (face_left == 2)   orient_to("left")   socket();
        if (face_right == 2)  orient_to("right")  socket();
    }
}

module stud() {
    translate([0, 0, block_size/2])
    union() {
        // We use difference() first to cut the GROOVE, then union() to add the RIDGE
        
        difference() {
            // 1. Base Cylinder
            union() {
                cylinder(h = stud_height - stud_lip, d = stud_diam);
                translate([0, 0, stud_height - stud_lip])
                cylinder(h = stud_lip, d1 = stud_diam, d2 = stud_diam - (stud_lip*2));
            }

            // 2. Cut the Proximal GROOVE (Near Base)
            if (enable_snap) {
                // Torus must intrude into the cylinder
                torus_major_r = (stud_diam / 2) + wave_radius - wave_amplitude;
                
                translate([0, 0, pos_groove_z])
                rotate_extrude()
                translate([torus_major_r, 0, 0])
                circle(r = wave_radius);
            }
        }

        // 3. Add the Distal RIDGE (Near Top)
        if (enable_snap) {
            // Torus must extrude out of the cylinder
            torus_major_r = (stud_diam / 2) - wave_radius + wave_amplitude;
            
            translate([0, 0, pos_ridge_z])
            rotate_extrude()
            translate([torus_major_r, 0, 0])
            circle(r = wave_radius);
        }
    }
}

module socket() {
    socket_d = stud_diam + tolerance;
    socket_h = stud_height + socket_depth_clearance;
    
    // Invert Z positions for the socket (relative to block face)
    // Groove on Stud -> Becomes Bump on Socket Wall
    // Ridge on Stud -> Becomes Groove on Socket Wall
    
    // Remember: Socket is a NEGATIVE volume.
    // To make a BUMP on the wall, we must REMOVE material from the negative cylinder (Difference).
    // To make a GROOVE on the wall, we must ADD material to the negative cylinder (Union).

    // Z positions relative to the hole opening (block face)
    // Hole goes into -Z (or +Z in this module logic before difference)
    // The "Proximal" groove of the stud (z=1.5) meets the "Entrance" of the socket.
    // The "Distal" ridge of the stud (z=3.5) meets the "Deep" part of the socket.
    
    // Socket Entrance (matches Stud Groove): Needs a BUMP.
    // Socket Deep (matches Stud Ridge): Needs a GROOVE.
    
    // Calculate Socket Z positions (Must match Stud exactly)
    // Stud Groove is at Z=1.5. Socket Bump must be at Z=1.5 from opening.
    groove_match_z = block_size/2 - pos_groove_z; 
    ridge_match_z  = block_size/2 - pos_ridge_z;

    translate([0, 0, block_size/2 - socket_h + 0.01]) 
    union() { // Everything here is REMOVED from the main block
        
        difference() {
            // 1. Main Hole
            union() {
                cylinder(h = socket_h, d = socket_d);
                translate([0, 0, socket_h - 1])
                cylinder(h = 1.1, d1 = socket_d, d2 = socket_d + 1.5);
            }

            // 2. Create BUMP at Entrance (to fit into Stud Groove)
            // We SUBTRACT from the hole cylinder to leave plastic behind
            if (enable_snap) {
                 // To leave a bump of 'amplitude', we subtract a torus that is smaller
                 // Torus edge should be at (SocketRadius - Amplitude)
                 // Math: Center = (SocketRadius - Amplitude - WaveRadius) ?? 
                 // Easier: Center = (SocketRadius) - WaveRadius - Amplitude
                 
                 torus_major_r = (socket_d / 2) + wave_radius - wave_amplitude;
                 
                 translate([0, 0, pos_groove_z]) // Matches stud height 1.5
                 rotate_extrude()
                 translate([torus_major_r, 0, 0])
                 circle(r = wave_radius); 
            }
        }
        
        // 3. Create GROOVE Deep Inside (to fit over Stud Ridge)
        // We ADD to the hole cylinder to cut more away from the block
        if (enable_snap) {
             torus_major_r = (socket_d / 2) - wave_radius + wave_amplitude;

             translate([0, 0, pos_ridge_z]) // Matches stud height 3.5
             rotate_extrude()
             translate([torus_major_r, 0, 0])
             circle(r = wave_radius + 0.05); // +0.05 extra clearance for the ridge
        }
    }
}

module chamfered_cube(size, r) {
    intersection() {
        cube([size, size, size], center=true);
        rotate([45, 0, 0]) cube([size, size * 1.414 - 2*r, size * 1.414 - 2*r], center=true);
        rotate([0, 45, 0]) cube([size * 1.414 - 2*r, size, size * 1.414 - 2*r], center=true);
        rotate([0, 0, 45]) cube([size * 1.414 - 2*r, size * 1.414 - 2*r, size], center=true);
    }
}

module orient_to(face) {
    if (face == "top")    children(); 
    if (face == "bottom") rotate([180, 0, 0]) children(); 
    if (face == "front")  rotate([-90, 0, 0]) children(); 
    if (face == "back")   rotate([90, 0, 0])  children(); 
    if (face == "left")   rotate([0, -90, 0]) children(); 
    if (face == "right")  rotate([0, 90, 0])  children(); 
}