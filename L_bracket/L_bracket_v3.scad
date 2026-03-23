/* ============================================================================
   Project      : Parametric Filleted L-Bracket
   File         : L_bracket_v3.scad
   Author       : Samet Ozer
   Role         : Mechanical Design / Parametric CAD Modeling
   Description  : Parametric OpenSCAD model of a filleted L-bracket generated
                  with Minkowski-based edge rounding. The model includes one
                  mounting hole on the base arm and one mounting hole on the
                  vertical arm.

   Parameters   : base_length      -> Length of the horizontal arm
                  overall_height   -> Total height of the vertical arm
                  width            -> Bracket width
                  thickness        -> Arm thickness
                  fillet_r         -> Fillet radius
                  hole_d           -> Mounting hole diameter
                  base_hole_x      -> Base hole X position
                  base_hole_y      -> Base hole Y position
                  vertical_hole_z  -> Vertical hole Z position
                  vertical_hole_y  -> Vertical hole Y position

   Units        : mm

   Notes        : The geometry is formed by combining two orthogonal arms and
                  applying a Minkowski operation for edge rounding. Hole layout
                  is preserved from the original design.

   Version      : 1.0
   ============================================================================ */


// ============================================================================
// Parameters
// ============================================================================

$fn = 40;

base_length    = 60;
overall_height = 50;
width          = 20;
thickness      = 5;

fillet_r       = 2;    // Fillet radius

hole_d         = 6;

base_hole_x    = 45;
base_hole_y    = width / 2;

vertical_hole_z = 30;
vertical_hole_y = width / 2;


// ============================================================================
// Base Geometry (Pre-Fillet Core Body)
// ============================================================================

module base_geometry() {
    union() {
        // Horizontal arm
        cube([
            base_length - 2 * fillet_r,
            width       - 2 * fillet_r,
            thickness   - 2 * fillet_r
        ]);

        // Vertical arm
        cube([
            thickness      - 2 * fillet_r,
            width          - 2 * fillet_r,
            overall_height - 2 * fillet_r
        ]);
    }
}


// ============================================================================
// Filleted Body
// ============================================================================

module filleted_body() {
    minkowski() {
        base_geometry();
        sphere(r = fillet_r);
    }
}


// ============================================================================
// Final Model
// ============================================================================

difference() {

    // Restore the outer dimensions after Minkowski rounding
    translate([fillet_r, fillet_r, fillet_r])
        filleted_body();

    // Base mounting hole (Z-axis direction)
    translate([base_hole_x, base_hole_y, -1])
        cylinder(
            h = thickness + 2,
            d = hole_d
        );

    // Vertical mounting hole (X-axis direction)
    translate([-1, vertical_hole_y, vertical_hole_z])
        rotate([0, 90, 0])
            cylinder(
                h = thickness + 2,
                d = hole_d
            );
}