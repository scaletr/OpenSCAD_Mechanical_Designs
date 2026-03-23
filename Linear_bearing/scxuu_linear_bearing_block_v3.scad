

/* ============================================================================
   Project      : SCxUU Linear Bearing Housing
   File         : scxuu_linear_bearing_block_v3.scad
   Author       : Samet Ozer
   Role         : Mechanical Design / Parametric CAD Modeling
   Description  : Parametric OpenSCAD model of an SCxUU-style linear bearing
                  housing block with mounting holes and retaining chamfer rings.
   Units        : mm
   Notes        : Some outer-body dimensions are defined to match the general
                  form of the component where full catalog geometry is not
                  explicitly available.
============================================================================ */


/* ============================================================================
   MAIN PARAMETERS [mm]
============================================================================ */

shaft_diameter                = 8;    // Shaft diameter
shaft_center_height           = 11;   // Shaft center height measured from the base
shaft_center_width_position   = 17;   // Shaft center position along body width

block_width_y                 = 34;   // Total body width in Y direction
block_height_x                = 22;   // Total body height in X direction
hole_platform_height_x        = 18;   // Height level of the mounting-hole platform
base_height_x                 = 6;    // Base height

mount_hole_spacing_y          = 24;   // Center-to-center spacing of mounting holes in Y
mount_hole_edge_offset_y      = 5;    // Edge offset of mounting holes
mount_screw_nominal_size      = 4;    // Nominal screw size reference (e.g. M4)
mount_hole_diameter           = 3.4;  // Mounting hole diameter

mount_hole_spacing_z          = 18;   // Center-to-center spacing of mounting holes in Z
block_length_z                = 30;   // Total body length in Z direction
screw_tap_depth               = 8;    // Reference screw engagement depth (not used in geometry)

side_fairing_angle_deg        = 45;   // Defined for reference; not actively used in current geometry
side_fairing_depth            = 2;    // Side transition / chamfer depth

linear_bearing_outer_diameter = 16;   // Outer diameter of the linear bearing
manufacturing_tolerance       = 0.2;  // Manufacturing / print tolerance


/* ============================================================================
   OPTIONAL SETTINGS
============================================================================ */

extra_block_length_z          = 0;       // Additional extension in Z direction
add_center_mount_holes        = false;   // Enables additional center holes when length is extended

ring_to_ring_distance         = 17.5 + extra_block_length_z;  // Distance between retaining rings
snap_ring_width               = 1.1;     // Retaining ring width
snap_ring_wall_thickness      = 0.3;     // Retaining ring wall thickness


/* ============================================================================
   MAIN BODY
============================================================================ */

union() {

    difference() {

        /* --------------------------------------------------------------------
           Outer body profile
        -------------------------------------------------------------------- */
        linear_extrude(height = block_length_z + extra_block_length_z) {
            polygon(points = [
                [0, 0],
                [base_height_x, 0],
                [base_height_x + side_fairing_depth, side_fairing_depth],
                [hole_platform_height_x, side_fairing_depth],
                [hole_platform_height_x,
                    ((block_width_y - mount_hole_spacing_y) / 2
                    + mount_screw_nominal_size / 2 + 1)],
                [block_height_x,
                    ((block_width_y - mount_hole_spacing_y) / 2
                    + mount_screw_nominal_size / 2 + 1)
                    + (block_height_x - hole_platform_height_x)],
                [block_height_x,
                    block_width_y
                    - ((block_width_y - mount_hole_spacing_y) / 2
                    + mount_screw_nominal_size / 2 + 1)
                    - (block_height_x - hole_platform_height_x)],
                [hole_platform_height_x,
                    block_width_y
                    - ((block_width_y - mount_hole_spacing_y) / 2
                    + mount_screw_nominal_size / 2 + 1)],
                [hole_platform_height_x, block_width_y - side_fairing_depth],
                [base_height_x + side_fairing_depth, block_width_y - side_fairing_depth],
                [base_height_x, block_width_y],
                [0, block_width_y],
                [0, block_width_y - (2 * mount_hole_edge_offset_y)],
                [1, block_width_y - (2 * mount_hole_edge_offset_y) - 1],
                [1, (2 * mount_hole_edge_offset_y) + 1],
                [0, (2 * mount_hole_edge_offset_y)]
            ]);
        }

        /* --------------------------------------------------------------------
           Linear bearing seat
        -------------------------------------------------------------------- */
        translate([
            shaft_center_height,
            shaft_center_width_position,
            -manufacturing_tolerance
        ]) {
            cylinder(
                h  = block_length_z + extra_block_length_z + 2 * manufacturing_tolerance,
                d  = linear_bearing_outer_diameter,
                $fn = 360
            );
        }

        /* --------------------------------------------------------------------
           Four mounting holes
        -------------------------------------------------------------------- */
        rotate([0, 90, 0]) {
            for (width_index = [0:1]) {
                for (length_index = [0:1]) {
                    translate([
                        (mount_hole_spacing_z - block_length_z) / 2
                            - length_index * (mount_hole_spacing_z + extra_block_length_z),
                        mount_hole_edge_offset_y + width_index * mount_hole_spacing_y,
                        -manufacturing_tolerance
                    ]) {
                        cylinder(
                            d   = mount_hole_diameter,
                            h   = mount_hole_spacing_y + 2 * manufacturing_tolerance + 30,
                            $fn = 360
                        );
                    }
                }
            }

            /* ----------------------------------------------------------------
               Optional center holes for extended body length
            ---------------------------------------------------------------- */
            if (extra_block_length_z > 0 && add_center_mount_holes) {
                for (width_index = [0:1]) {
                    for (length_index = [0:1]) {
                        translate([
                            (mount_hole_spacing_z - (block_length_z + extra_block_length_z)) / 2
                                - length_index * mount_hole_spacing_z,
                            mount_hole_edge_offset_y + width_index * mount_hole_spacing_y,
                            -manufacturing_tolerance
                        ]) {
                            cylinder(
                                d   = mount_hole_diameter,
                                h   = mount_hole_spacing_y + 2 * manufacturing_tolerance + 30,
                                $fn = 360
                            );
                        }
                    }
                }
            }
        }
    }

    /* ------------------------------------------------------------------------
       Two chamfered retaining rings to keep the linear bearing in position
    ------------------------------------------------------------------------ */
    for (ring_direction = [-1, 1]) {
        translate([
            shaft_center_height,
            shaft_center_width_position,
            ring_direction * ((ring_to_ring_distance - snap_ring_width) / 2)
                + (block_length_z + extra_block_length_z) / 2
        ]) {
            chamferRing(
                linear_bearing_outer_diameter + manufacturing_tolerance,
                linear_bearing_outer_diameter - 2 * snap_ring_wall_thickness,
                snap_ring_width
            );
        }
    }
}


/* ============================================================================
   CHAMFERED RING MODULE
============================================================================ */

module chamferRing(outer_diameter, inner_diameter, ring_height) {
    difference() {

        cylinder(
            h      = ring_height,
            d      = outer_diameter,
            $fn    = 360,
            center = true
        );

        cylinder(
            h      = ring_height + 1,
            d      = inner_diameter,
            $fn    = 360,
            center = true
        );

        for (ring_side = [-1, 1]) {
            translate([0, 0, ring_side * (ring_height / 2)]) {

                inner_radius = inner_diameter / 2;
                outer_radius = outer_diameter / 2;

                cylinder(
                    h      = ring_height / 4,
                    r1     = ring_side * ((inner_radius - outer_radius) / 2)
                           + (inner_radius + outer_radius) / 2,
                    r2     = ring_side * ((outer_radius - inner_radius) / 2)
                           + (inner_radius + outer_radius) / 2,
                    $fn    = 360,
                    center = true
                );
            }
        }
    }
}