/* ============================================================================
   Project      : Parametric Elbow Pipe with Dual Flanges
   File         : elbow_pipe_dual_flange_v5.scad
   Author       : Samet Ozer
   Role         : Mechanical Design / Parametric CAD Modeling
   Description  : Parametric OpenSCAD model of a bent pipe with two flange
                  terminations. The design includes a constant inner diameter,
                  bolt-hole pattern, captured elbow-to-flange transition, and
                  an internal straight liner extension toward the flange face.

   Parameters   : pipe_inner_d    -> Inner diameter of the pipe
                  pipe_wall       -> Pipe wall thickness
                  bend_radius     -> Elbow centerline bend radius
                  bend_angle      -> Elbow bend angle

                  flange_outer_d  -> Outer diameter of the flange
                  flange_thick    -> Flange thickness
                  flange_neck_len -> Neck extension length at flange root
                  capture_len     -> Captured outer geometry length from elbow
                  merge_overlap   -> Small overlap for robust CSG merging
                  liner_len       -> Internal straight pipe extension into flange

                  bolt_count      -> Number of bolt holes
                  bolt_circle_d   -> Bolt circle diameter
                  bolt_hole_d     -> Bolt hole diameter

   Units        : mm

   Notes        : Geometry and modeling logic are preserved from the original
                  design. This revision standardizes formatting, English
                  comments, alignment, and code readability only.

   Version      : 5.0
   ============================================================================ */


// ============================================================================
// Global Resolution
// ============================================================================

$fn = 140;


// ============================================================================
// Input Parameters
// ============================================================================

// Pipe

pipe_inner_d    = 88;
pipe_wall       = 8;
bend_radius     = 225;
bend_angle      = -90;

// Flange

flange_outer_d  = 180;
flange_thick    = 16;
flange_neck_len = 10;
capture_len     = 8;
merge_overlap   = 0.25;

// Internal straight liner extension toward the flange side
liner_len       = flange_thick;

// Bolt holes

bolt_count      = 4;
bolt_circle_d   = 140;
bolt_hole_d     = 12;


// ============================================================================
// Derived Dimensions
// ============================================================================

pipe_inner_r    = pipe_inner_d / 2;
pipe_outer_r    = pipe_inner_r + pipe_wall;

flange_outer_r  = flange_outer_d / 2;
bolt_circle_r   = bolt_circle_d / 2;
bolt_hole_r     = bolt_hole_d / 2;


// ============================================================================
// Design Checks
// ============================================================================

assert(pipe_inner_d > 0, "pipe_inner_d must be > 0");
assert(pipe_wall > 0, "pipe_wall must be > 0");
assert(
    flange_outer_r > pipe_outer_r,
    "Flange outer radius must be greater than pipe outer radius"
);
assert(
    bolt_circle_r + bolt_hole_r < flange_outer_r,
    "Bolt holes extend beyond the flange outer diameter"
);
assert(
    bolt_circle_r - bolt_hole_r > pipe_outer_r,
    "Bolt holes intersect the pipe region"
);
assert(liner_len > 0, "liner_len must be > 0");


// ============================================================================
// Elbow Pipe
// ============================================================================

module elbow_pipe() {
    rotate_extrude(angle = bend_angle, convexity = 20)
        translate([-bend_radius, 0, 0])
            difference() {
                circle(r = pipe_outer_r);
                circle(r = pipe_inner_r);
            }
}


// ============================================================================
// Flange Outer Body
// No outer fillet is applied
// ============================================================================

module flange_outer_body() {
    rotate_extrude(convexity = 20)
        polygon([
            [pipe_outer_r,   flange_neck_len],
            [pipe_outer_r,   0],
            [flange_outer_r, 0],
            [flange_outer_r, -flange_thick],
            [pipe_outer_r,   -flange_thick],
            [pipe_outer_r,   flange_neck_len]
        ]);
}


// ============================================================================
// Internal Holes
// ============================================================================

module flange_holes() {
    union() {
        // Main internal passage with constant diameter
        translate([0, 0, -flange_thick - 1])
            cylinder(
                h = flange_thick + flange_neck_len + capture_len + liner_len + 4,
                r = pipe_inner_r
            );

        // Bolt holes
        for (i = [0 : bolt_count - 1]) {
            rotate([0, 0, i * 360 / bolt_count])
                translate([bolt_circle_r, 0, -flange_thick - 1])
                    cylinder(
                        h = flange_thick + 2,
                        r = bolt_hole_r
                    );
        }
    }
}


// ============================================================================
// Extract Exact Outer Geometry from the Elbow
// ============================================================================

module exact_elbow_capture(angle_deg = 0, inward_sign = 1) {
    a    = angle_deg;
    p    = [-bend_radius * cos(a), -bend_radius * sin(a), 0];

    tx   = inward_sign * sin(a);
    ty   = inward_sign * (-cos(a));
    axis = [-ty, tx, 0];

    translate(p)
        rotate(a = 90, v = axis)
            intersection() {
                elbow_pipe();

                translate([0, 0, -merge_overlap])
                    cylinder(
                        h = capture_len + merge_overlap,
                        r = pipe_outer_r + 0.02
                    );
            }
}


// ============================================================================
// Single Flange
// ============================================================================

module flange_with_holes(angle_deg = 0, inward_sign = 1) {
    a    = angle_deg;
    p    = [-bend_radius * cos(a), -bend_radius * sin(a), 0];

    tx   = inward_sign * sin(a);
    ty   = inward_sign * (-cos(a));
    axis = [-ty, tx, 0];

    translate(p)
        rotate(a = 90, v = axis)
            difference() {
                union() {
                    // Flange body
                    flange_outer_body();

                    // Gap-free outer merge with captured elbow geometry
                    exact_elbow_capture(angle_deg, inward_sign);

                    // Extend the internal pipe sleeve toward the flange side
                    translate([0, 0, -liner_len])
                        difference() {
                            cylinder(
                                h = liner_len + merge_overlap,
                                r = pipe_outer_r
                            );
                            cylinder(
                                h = liner_len + merge_overlap,
                                r = pipe_inner_r
                            );
                        }
                }

                // Maintain a straight and constant internal bore
                flange_holes();
            }
}


// ============================================================================
// Local Assembly
// ============================================================================

module local_assembly() {
    union() {
        elbow_pipe();

        flange_with_holes(0, 1);
        flange_with_holes(bend_angle, -1);
    }
}


// ============================================================================
// Final Assembly Orientation
// ============================================================================

module assembly() {
    rotate([90, 0, 0])
        local_assembly();
}


// ============================================================================
// Example Usage
// ============================================================================

assembly();