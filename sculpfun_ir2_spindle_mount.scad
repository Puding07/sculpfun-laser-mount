// =====================================================================
//  Sculpfun iR-2 lézertartó vízhűtéses spindle-re (LeadCNC 1010)
//  Parametrikus OpenSCAD modell
//
//  Részek:
//    clamp_right  - bilincs jobb fele, rajta a tartófül (lézer oldal)
//    clamp_left   - bilincs bal fele (anyacsapdákkal)
//    bracket      - lézertartó lap: függőleges hosszlyukak (fókusz/magasság
//                   állítás) + a lézer rögzítő furatai
//    assembly     - összeállítás nézet dummy spindle-lel és lézerrel
//
//  Koordináták: a spindle tengelye a Z tengely, origó a bilincs alja.
//  A lézer a +X oldalon van.
//
//  !!! NYOMTATÁS ELŐTT MÉRD MEG: spindle_d, és a lézer furatkiosztását
//      (laser_holes), lásd README.md !!!
// =====================================================================

/* [Mit renderel] */
part = "assembly"; // [assembly, clamp_right, clamp_left, bracket, print_all]

/* [Spindle] */
spindle_d        = 85;    // MÉRD MEG tolómérővel! (sok 2.2kW spindle 80 mm)
clamp_clearance  = 0.3;   // radiális hézag; gumicsíkhoz add hozzá a vastagságát
clamp_h          = 35;    // bilincs magassága
clamp_wall       = 7;     // gyűrű falvastagság
split_gap        = 3;     // rés a két fél között (ennyit tud szorítani)

/* [Tartófül a bilincsen] */
tab_len          = 32;    // fül kinyúlása a gyűrűből (+X)
tab_t            = 14;    // fül vastagsága (Y)

/* [Tartólap] */
plate_t          = 8;     // lap vastagsága
slot_travel      = 40;    // magasság-állítási tartomány (±20 mm)
laser_gap        = 3;     // távolság a fül vége és a lézer között
laser_w          = 50;    // a lézer lapra fekvő oldalának szélessége
laser_h          = 144;   // lézer magassága (csak az összeállításhoz)
laser_d          = 58;    // lézer mélysége (csak az összeállításhoz)
laser_top_z      = 35;    // a lézer teteje a bilincs aljához képest
laser_plate_h    = 90;    // a lap magassága a lézer tetejétől lefelé
adj              = 0;     // összeállításban: magasság-állítás (-20..+20)

/* [Lézer furatok] */
// [x, z] a lézer hátlapjának felső-közép pontjától (x: oldalra, z: lefelé negatív)
// !!! HELYŐRZŐ ÉRTÉKEK - mérd le a lézeren / a mellékelt univerzális lapon !!!
laser_holes      = [[-10, -20], [10, -20], [-10, -60], [10, -60]];
laser_hole_d     = 3.4;   // M3
laser_hole_slot  = 4;     // a furatok függőleges hosszlyuk-hossza (finom állítás)

/* [Csavarok] */
m5_d       = 5.5;
m5_head_d  = 10;
m5_head_h  = 5.5;
m5_nut_af  = 8.3;   // M5 anya laptávolság + tűrés
m5_nut_h   = 4.6;

$fn = 96;
eps = 0.01;

// ---------------- származtatott méretek ----------------
R_in   = spindle_d/2 + clamp_clearance;
R_out  = R_in + clamp_wall;
ear_t  = 13;                       // fül vastagság X irányban (fél-bilincsenként)
bolt_y = R_in + 5.5;               // szorítócsavarok Y pozíciója
ear_y1 = bolt_y + 7;               // fül vége
clamp_bolt_z = [clamp_h*0.27, clamp_h*0.73];

tab_x0  = R_in + 2;
tab_x1  = R_out + tab_len;
tab_bolt_x = [R_out + 8, R_out + tab_len - 8];
tab_bolt_z = clamp_h/2;

plate_y0 = tab_t/2;
plate_x0 = R_out + 1;
laser_x0 = tab_x1 + laser_gap;
laser_cx = laser_x0 + laser_w/2;
plate_x1 = laser_x0 + laser_w;
plate_z0 = min(tab_bolt_z - slot_travel/2 - 8, laser_top_z - laser_plate_h);
plate_z1 = max(tab_bolt_z + slot_travel/2 + 8, laser_top_z);

// ---------------- segédek ----------------
module hex_pocket(af, h) { cylinder(d = af/cos(30), h = h, $fn = 6); }

// félgyűrű + fülek; side = +1 (jobb) vagy -1 (bal)
module clamp_half_body(side) {
    xoff = split_gap/2;
    intersection() {
        union() {
            cylinder(r = R_out, h = clamp_h);
            // szorító fülek elöl/hátul
            for (s = [-1, 1])
                translate([0, s > 0 ? R_in : -ear_y1, 0])
                    cube([xoff + ear_t, ear_y1 - R_in, clamp_h]);
        }
        translate([xoff, -500, -1]) cube([1000, 1000, clamp_h + 2]);
    }
}

module clamp_bolt_holes(side) {
    xoff = split_gap/2;
    for (s = [-1, 1], z = clamp_bolt_z) {
        translate([0, s*bolt_y, z]) rotate([0, 90, 0]) {
            translate([0, 0, -1]) cylinder(d = m5_d, h = 100);
            if (side > 0)   // csavarfej süllyesztés
                translate([0, 0, xoff + ear_t - m5_head_h]) cylinder(d = m5_head_d, h = 20);
            else            // anyacsapda
                translate([0, 0, xoff + ear_t - m5_nut_h]) rotate([0, 0, 30]) hex_pocket(m5_nut_af, 20);
        }
    }
}

module clamp_right() {
    difference() {
        union() {
            clamp_half_body(1);
            // lézer tartófül
            translate([tab_x0, -tab_t/2, 0]) cube([tab_x1 - tab_x0, tab_t, clamp_h]);
            // erősítő borda a fül tövénél
            hull() {
                translate([R_out - 3, -tab_t/2 - 6, 0]) cube([1, tab_t + 12, clamp_h]);
                translate([R_out + 10, -tab_t/2, 0]) cube([1, tab_t, clamp_h]);
            }
        }
        translate([0, 0, -1]) cylinder(r = R_in, h = clamp_h + 2);
        clamp_bolt_holes(1);
        // tartólap csavarok (Y irányban) + anyacsapda a -Y oldalon
        for (x = tab_bolt_x)
            translate([x, 0, tab_bolt_z]) rotate([90, 0, 0]) {
                translate([0, 0, -50]) cylinder(d = m5_d, h = 100);
                translate([0, 0, tab_t/2 - m5_nut_h]) rotate([0, 0, 30]) hex_pocket(m5_nut_af, 20);
            }
    }
}

module clamp_left() {
    mirror([1, 0, 0]) difference() {
        clamp_half_body(-1);
        translate([0, 0, -1]) cylinder(r = R_in, h = clamp_h + 2);
        clamp_bolt_holes(-1);
    }
}

module bracket() {
    difference() {
        translate([plate_x0, plate_y0, plate_z0])
            cube([plate_x1 - plate_x0, plate_t, plate_z1 - plate_z0]);
        // függőleges hosszlyukak a fül csavarjaihoz
        for (x = tab_bolt_x)
            hull() for (dz = [-slot_travel/2, slot_travel/2])
                translate([x, 0, tab_bolt_z + dz]) rotate([-90, 0, 0])
                    cylinder(d = m5_d, h = 100);
        // lézer furatok (rövid függőleges hosszlyukkal)
        for (p = laser_holes)
            hull() for (dz = [-laser_hole_slot/2, laser_hole_slot/2])
                translate([laser_cx + p[0], 0, laser_top_z + p[1] + dz]) rotate([-90, 0, 0])
                    cylinder(d = laser_hole_d, h = 100);
    }
}

// ---------------- összeállítás ----------------
module dummy_spindle() {
    color("silver", 0.6) translate([0, 0, -90]) cylinder(d = spindle_d, h = 260);
    color("gold", 0.8) translate([0, 0, -115]) cylinder(d = 30, h = 25);
}
module dummy_laser() {
    color("dimgray", 0.8)
        translate([laser_x0, plate_y0 + plate_t, laser_top_z - laser_h + adj])
            cube([laser_w, laser_d, laser_h]);
}

module assembly() {
    dummy_spindle();
    color("orange") clamp_right();
    color("darkorange") clamp_left();
    color("deepskyblue") translate([0, 0, adj]) bracket();
    dummy_laser();
}

// nyomtatási tájolás: a lap fektetve
module bracket_print() {
    translate([-plate_x0, 0, 0]) rotate([90, 0, 0]) translate([0, -plate_y0, 0]) bracket();
}

if (part == "assembly")    assembly();
if (part == "clamp_right") clamp_right();
if (part == "clamp_left")  clamp_left();
if (part == "bracket")     bracket_print();
if (part == "print_all") {
    clamp_right();
    translate([-15, 0, 0]) clamp_left();
    translate([0, -R_out - 70, 0]) bracket_print();
}
