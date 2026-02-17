// ==========================================
// NUMBERBLOCKS: MODULAR FACE PLATE (V2)
// Clean Chamfered Edges using Hull
// ==========================================

/* [Global Dimensions] */
plate_size = 28.0;      // 28mm square (leaves a 1mm border on the block)
plate_thickness = 1.6;  // 2mm total thickness
chamfer_size = .5;     // Horizontal size of the 45-degree slope

/* [Connector Settings - MUST MATCH BLOCK] */
// These ensure the snap fit works with the previous block script
stud_diam = 16.0;
stud_height = 5.0;
stud_lip = 0.5;

/* [S-Curve Wave Settings - MUST MATCH BLOCK] */
enable_snap = true;
wave_amplitude = 0.20; 
wave_radius = 2.0;     
pos_groove_z = 1.5;    
pos_ridge_z = 3.5;     

$fn = 80; // High resolution for smooth snaps

// ==========================================
// MAIN RENDER
// ==========================================

// We rotate it over so you can see the connector in the preview
rotate([180,0,0])
face_plate_assembly();

// ==========================================
// MODULES
// ==========================================

module face_plate_assembly() {
    union() {
        // 1. The Clean Chamfered Plate
        clean_chamfered_plate(plate_size, plate_thickness, chamfer_size);
        
        // 2. The Male Stud (attached to the bottom face)
        // The stud module builds upwards from Z=0. 
        // Since our plate is built upwards from Z=0, we need to mirror the stud
        // to point downwards from the bottom face.
        mirror([0,0,1])
        stud();
    }
}

// --- NEW CLEAN PLATE MODULE ---
module clean_chamfered_plate(size, thick, chamfer) {
    // We use hull() to create a shape that transitions from a full-size 
    // square at the bottom to a slightly smaller square at the top.
    
    h_outer = size/2;            // Outer border distance from center
    h_inner = (size/2) - chamfer; // Inner border distance (top surface)

    hull() {
        // Bottom Plane (Z=0) - Full Size corners
        // We use tiny slivers of cubes to define the corners for the hull
        translate([-h_outer, -h_outer, 0]) linear_extrude(0.01) square(0.01, center=true);
        translate([ h_outer, -h_outer, 0]) linear_extrude(0.01) square(0.01, center=true);
        translate([ h_outer,  h_outer, 0]) linear_extrude(0.01) square(0.01, center=true);
        translate([-h_outer,  h_outer, 0]) linear_extrude(0.01) square(0.01, center=true);

        // Top Plane (Z=thick) - Inset corners
        translate([-h_inner, -h_inner, thick-0.01]) linear_extrude(0.01) square(0.01, center=true);
        translate([ h_inner, -h_inner, thick-0.01]) linear_extrude(0.01) square(0.01, center=true);
        translate([ h_inner,  h_inner, thick-0.01]) linear_extrude(0.01) square(0.01, center=true);
        translate([-h_inner,  h_inner, thick-0.01]) linear_extrude(0.01) square(0.01, center=true);
    }
}


// --- STUD MODULE (Same as before) ---
module stud() {
    union() {
        difference() {
            // Base Cylinder
            union() {
                cylinder(h = stud_height - stud_lip, d = stud_diam);
                translate([0, 0, stud_height - stud_lip])
                cylinder(h = stud_lip, d1 = stud_diam, d2 = stud_diam - (stud_lip*2));
            }

            // Proximal GROOVE (Near base)
            if (enable_snap) {
                torus_major_r = (stud_diam / 2) + wave_radius - wave_amplitude;
                translate([0, 0, pos_groove_z])
                rotate_extrude()
                translate([torus_major_r, 0, 0])
                circle(r = wave_radius);
            }
        }

        // Distal RIDGE (Near tip)
        if (enable_snap) {
            torus_major_r = (stud_diam / 2) - wave_radius + wave_amplitude;
            translate([0, 0, pos_ridge_z])
            rotate_extrude()
            translate([torus_major_r, 0, 0])
            circle(r = wave_radius);
        }
    }
}