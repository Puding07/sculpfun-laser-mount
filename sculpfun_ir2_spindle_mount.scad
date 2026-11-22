// =====================================================================
//  Sculpfun iR-2 lézertartó vízhűtéses spindle-re (LeadCNC 1010)
//  Parametrikus OpenSCAD modell - SF-A9 stílusú fecskefarkas gyorsrögzítő
//
//  Részek:
//    clamp_right   - bilincs jobb fele, rajta a tartófül (lézer oldal)
//    clamp_left    - bilincs bal fele (anyacsapdákkal)
//    bracket       - tartólap: magasságállító hosszlyukak + fecskefarkas
//                    befogó fix pofával, alsó ütközővel és ellentartóval
//    jaw           - mozgó pofa (a gombos csavar tolja)
//    knob          - recés gomb M5 hatlapfejű csavarhoz
//    receiver_test - 20 mm-es próbadarab a sín illesztésének teszteléséhez
//    jaw_test      - 20 mm-es mozgó pofa a próbadarabhoz
//    assembly      - összeállítás nézet
//
//  Koordináták: a spindle tengelye a Z tengely, origó a bilincs alja.
//  A tartólap a spindle +X oldalán, a spindle-lel párhuzamosan áll (plate_gap
//  távolságra), a lézer közepe a bilincs közepével egy vonalban van (Y = 0).
//  A sín függőleges, a lézer felülről csúszik be az alsó ütközőig, a gombbal
//  oldalról szorítható.
// =====================================================================

/* [Mit renderel] */
part = "assembly"; // [assembly, clamp_right, clamp_left, bracket, jaw, knob, receiver_test, jaw_test, print_all]

/* [Spindle] */
spindle_d        = 80;    // lemérve: 80 mm
clamp_clearance  = 0.3;   // radiális hézag; gumicsíkhoz add hozzá a vastagságát
clamp_h          = 35;
clamp_wall       = 7;
split_gap        = 3;

/* [Tartó talp a bilincsen] */
pad_w            = 44;    // a talp szélessége (Y)
pad_bolt_y       = 12;    // a két rögzítőcsavar ±Y pozíciója

/* [Tartólap] */
plate_gap        = 13;    // távolság a spindle palástja és a tartólap között (min. 13)
plate_t          = 11;    // vastag, hogy a csavarfejek a felület alá süllyedjenek
slot_travel      = 40;    // magasság-állítás (±20 mm)
knob_side        = 1;     // 1: gomb +Y felé, -1: gomb -Y felé (tükrözés)
rec_z0           = -60;   // a sín alsó vége (ütköző) a bilincs aljához képest
adj              = 0;     // összeállításban: magasság-állítás (-20..+20)

/* [Lézer sín (dovetail) - a lézer hátulján] */
rail_w           = 51;    // a sín legszélesebb mérete (a lézertől legtávolabbi lapon) - MÉRD MEG
rail_h           = 5.8;   // a sín vastagsága (lemérve)
rail_len         = 77;    // a sín hossza (csak az összeállításhoz)
rail_lip         = 1.0;   // függőleges rész a sín külső élén a 45°-os ferde előtt
rail_clr         = 0.2;   // hézag a pofáknál
jaw_h            = 5.0;   // pofa magasság (kisebb mint rail_h, hogy ne érjen a lézerházhoz)
rec_len          = 60;    // a befogó hossza

/* [Lézer test (összeállításhoz és ütközéshez)] */
laser_w          = 58;    // a hátlap szélessége (a sín felőli oldal)
laser_d          = 50;    // mélység
laser_h          = 144;
rail_to_lens     = 12;    // a sín alsó vége és a lézerház alja közti távolság

/* [Csavarok] */
m5_d       = 5.5;
m5_head_d  = 10;
m5_head_h  = 5.5;
m5_nut_af  = 8.3;
m5_nut_h   = 4.6;
m4_d       = 4.5;
m4_head_d  = 8.0;
m4_nut_af  = 7.3;
m4_nut_h   = 5.2;   // nyloc

$fn = 64;

// ---------------- származtatott: bilincs ----------------
R_in   = spindle_d/2 + clamp_clearance;
R_out  = R_in + clamp_wall;
ear_t  = 13;
bolt_y = R_in + 5.5;
ear_y1 = bolt_y + 7;
clamp_bolt_z = [clamp_h*0.27, clamp_h*0.73];

plate_x0   = spindle_d/2 + plate_gap;   // a tartólap belső (spindle felőli) síkja
X0         = plate_x0 + plate_t;        // a tartólap külső síkja
pad_bolt_z = clamp_h/2;
pad_nut_x  = R_in + 6.5;                // anyahorony helye a talpban

// ---------------- származtatott: befogó (lokális koordináták) ----------------
// lokális: x = szélesség (0 = sín közepe), y = sín iránya (0 = alsó ütköző, felfelé +),
//          z = a lap felületétől kifelé (a lézer felé)
undercut   = jaw_h - rail_lip;              // 45° -> vízszintes alávágás
fj_xi      = -(rail_w/2 + rail_clr);        // fix pofa belső éle
fj_w       = 8;
mj_xi      = rail_w/2 + rail_clr;           // mozgó pofa belső éle (névleges)
boss_x0    = max(mj_xi + 5, laser_w/2 + 1.5); // a magas rész a lézerházon kívül
boss_w     = 22;
boss_h     = 12;
mj_x1      = boss_x0 + boss_w;
guide_x    = boss_x0 + boss_w/2;
travel_out = 5;    // ennyit tud kifelé nyílni a pofa (névlegeshez képest)
travel_in  = 3;    // ennyit befelé (keskenyebb sínhez)
ab_x0      = mj_x1 + travel_out;
ab_w       = 10;
ab_x1      = ab_x0 + ab_w;
push_z     = 6;
stop_len   = 5;
stop_h     = 4;

function guide_ys(L) = L >= 40 ? [L*0.2, L*0.8] : [L/2];

// lokális -> globális (tartólap) transzformáció
// lokális x -> globális Y, lokális y (sín iránya) -> globális Z, lokális z -> globális +X
module to_plate(z0) {
    mirror([0, knob_side < 0 ? 1 : 0, 0])
        multmatrix([[0,0,1,X0],[1,0,0,0],[0,1,0,z0],[0,0,0,1]]) children();
}

// ---------------- segédek ----------------
module hex_pocket(af, h) { cylinder(d = af/cos(30), h = h, $fn = 6); }
module extrude_y(L) { translate([0, L, 0]) rotate([90, 0, 0]) linear_extrude(L) children(); }

// ======================= BILINCS =======================
module clamp_half_body() {
    xoff = split_gap/2;
    intersection() {
        union() {
            cylinder(r = R_out, h = clamp_h, $fn = 128);
            for (s = [-1, 1])
                translate([0, s > 0 ? R_in : -ear_y1, 0])
                    cube([xoff + ear_t, ear_y1 - R_in, clamp_h]);
        }
        translate([xoff, -500, -1]) cube([1000, 1000, clamp_h + 2]);
    }
}

module clamp_bolt_holes(side) {
    xoff = split_gap/2;
    for (s = [-1, 1], z = clamp_bolt_z)
        translate([0, s*bolt_y, z]) rotate([0, 90, 0]) {
            translate([0, 0, -1]) cylinder(d = m5_d, h = 100);
            if (side > 0)
                translate([0, 0, xoff + ear_t - m5_head_h]) cylinder(d = m5_head_d, h = 20);
            else
                translate([0, 0, xoff + ear_t - m5_nut_h]) rotate([0, 0, 30]) hex_pocket(m5_nut_af, 20);
        }
}

module clamp_right() {
    difference() {
        union() {
            clamp_half_body();
            // talp a tartólapnak
            translate([R_in + 1, -pad_w/2, 0]) cube([plate_x0 - (R_in + 1), pad_w, clamp_h]);
        }
        translate([0, 0, -1]) cylinder(r = R_in, h = clamp_h + 2, $fn = 128);
        clamp_bolt_holes(1);
        // tartólap csavarok (X irányban) + anyahorony felülről
        for (y = [-pad_bolt_y, pad_bolt_y]) {
            translate([R_in + 0.5, y, pad_bolt_z]) rotate([0, 90, 0]) cylinder(d = m5_d, h = 50);
            translate([pad_nut_x - m5_nut_h/2, y - m5_nut_af/2, pad_bolt_z - m5_nut_af/cos(30)/2])
                cube([m5_nut_h, m5_nut_af, 50]);
        }
    }
}

module clamp_left() {
    mirror([1, 0, 0]) difference() {
        clamp_half_body();
        translate([0, 0, -1]) cylinder(r = R_in, h = clamp_h + 2, $fn = 128);
        clamp_bolt_holes(-1);
    }
}

// ======================= BEFOGÓ (lokális) =======================
module fixed_jaw_2d() {
    polygon([[fj_xi, 0], [fj_xi, rail_lip], [fj_xi + undercut, jaw_h],
             [fj_xi - fj_w, jaw_h], [fj_xi - fj_w, 0]]);
}
module moving_jaw_2d() {
    polygon([[mj_xi, 0], [mj_x1, 0], [mj_x1, boss_h], [boss_x0, boss_h],
             [boss_x0, jaw_h], [mj_xi - undercut, jaw_h], [mj_xi, rail_lip]]);
}

// a lapra épülő részek: fix pofa, ütköző, ellentartó
module receiver_add(L) {
    extrude_y(L) fixed_jaw_2d();
    translate([-10, -stop_len, 0]) cube([20, stop_len, stop_h]);
    translate([ab_x0, L/2 - 8, 0]) cube([ab_w, 16, boss_h]);
}
// a lapból kivont részek
module receiver_sub(L, pt) {
    // vezetőcsavarok M4 + nyloc anya hátul
    for (gy = guide_ys(L)) translate([guide_x, gy, 0]) {
        translate([0, 0, -pt - 1]) cylinder(d = m4_d, h = pt + 2);
        translate([0, 0, -pt - 1]) rotate([0, 0, 30]) hex_pocket(m4_nut_af, m4_nut_h + 1);
    }
    // tolócsavar M5 + anyahorony felülről
    translate([ab_x0 - 1, L/2, push_z]) rotate([0, 90, 0]) cylinder(d = m5_d, h = ab_w + 2);
    translate([ab_x0 + ab_w/2 - m5_nut_h/2, L/2 - m5_nut_af/2, push_z - m5_nut_af/cos(30)/2])
        cube([m5_nut_h, m5_nut_af, 50]);
}
// a lap alapformája lokálisan
module receiver_base(L, pt) {
    translate([fj_xi - fj_w, -stop_len, -pt]) cube([ab_x1 - (fj_xi - fj_w), L + stop_len, pt]);
}

module moving_jaw(L) {
    difference() {
        extrude_y(L) moving_jaw_2d();
        for (gy = guide_ys(L)) {
            hull() for (dx = [-travel_out, travel_in])
                translate([guide_x + dx, gy, -1]) cylinder(d = m4_d, h = 50);
            hull() for (dx = [-travel_out, travel_in])
                translate([guide_x + dx, gy, 5]) cylinder(d = m4_head_d + 0.5, h = 50);
        }
        // kis mélyedés a tolócsavar hegyének
        translate([mj_x1 + 0.01, L/2, push_z]) rotate([0, -90, 0]) cylinder(d1 = 5, d2 = 0, h = 2.5);
    }
}

// ======================= TARTÓLAP =======================
module bracket() {
    slot_z0 = pad_bolt_z - slot_travel/2 - 9;
    slot_z1 = pad_bolt_z + slot_travel/2 + 9;
    ys  = [fj_xi - fj_w, ab_x1];
    ry0 = knob_side > 0 ? ys[0] : -ys[1];
    ry1 = knob_side > 0 ? ys[1] : -ys[0];
    rz0 = rec_z0 - stop_len;
    rz1 = rec_z0 + rec_len;
    difference() {
        union() {
            hull() {
                translate([plate_x0, -pad_w/2, slot_z0]) cube([plate_t, pad_w, slot_z1 - slot_z0]);
                translate([plate_x0, ry0, rz0]) cube([plate_t, ry1 - ry0, rz1 - rz0]);
            }
            to_plate(rec_z0) receiver_add(rec_len);
        }
        // függőleges hosszlyukak, süllyesztett csavarfejjel (a sín átcsúszik felettük)
        for (y = [-pad_bolt_y, pad_bolt_y]) {
            hull() for (dz = [-slot_travel/2, slot_travel/2])
                translate([plate_x0 - 1, y, pad_bolt_z + dz]) rotate([0, 90, 0]) cylinder(d = m5_d, h = 50);
            hull() for (dz = [-slot_travel/2, slot_travel/2])
                translate([X0 - m5_head_h - 0.6, y, pad_bolt_z + dz]) rotate([0, 90, 0]) cylinder(d = m5_head_d, h = 50);
        }
        to_plate(rec_z0) receiver_sub(rec_len, plate_t);
    }
}

module receiver_test() {
    L = 20; pt = 5;
    difference() {
        union() { receiver_base(L, pt); receiver_add(L); }
        receiver_sub(L, pt);
    }
}

// ======================= GOMB =======================
module knob() {
    difference() {
        union() {
            cylinder(d = 26, h = 10);
            translate([0, 0, 10]) cylinder(d1 = 14, d2 = 12, h = 4);
        }
        for (a = [0:30:359]) rotate([0, 0, a]) translate([13.5, 0, -1]) cylinder(d = 4, h = 12);
        translate([0, 0, -1]) cylinder(d = m5_d, h = 20);
        translate([0, 0, -1]) rotate([0, 0, 30]) hex_pocket(8.3, 5.5);   // M5 hatlapfej
    }
}

// ======================= ÖSSZEÁLLÍTÁS =======================
module dummy_spindle() {
    color("silver", 0.6) translate([0, 0, -90]) cylinder(d = spindle_d, h = 260);
    color("gold", 0.8) translate([0, 0, -115]) cylinder(d = 30, h = 25);
}
module dummy_laser() {
    zb = rec_z0 + adj - rail_to_lens;
    color("teal", 0.85) translate([X0 + rail_h, -laser_w/2, zb]) cube([laser_d, laser_w, laser_h]);
    // sín (trapéz)
    color("cadetblue") to_plate(rec_z0 + adj) extrude_y(rail_len)
        polygon([[-rail_w/2, 0], [rail_w/2, 0], [rail_w/2, rail_lip],
                 [rail_w/2 - undercut - (rail_h - jaw_h), rail_h],
                 [-rail_w/2 + undercut + (rail_h - jaw_h), rail_h], [-rail_w/2, rail_lip]]);
    // fókuszgomb
    color("dimgray") translate([X0 + rail_h + laser_d/2, 0, zb - 10]) cylinder(d = 22, h = 10);
}

module assembly() {
    dummy_spindle();
    color("orange") clamp_right();
    color("darkorange") clamp_left();
    translate([0, 0, adj]) {
        color("deepskyblue") bracket();
        color("tomato") to_plate(rec_z0) moving_jaw(rec_len);
        color("black") to_plate(rec_z0) translate([ab_x1 + 1, rec_len/2, push_z]) rotate([0, 90, 0]) knob();
    }
    dummy_laser();
}

// ======================= NYOMTATÁSI TÁJOLÁS =======================
module bracket_print() {
    rotate([0, -90, 0]) translate([-plate_x0, 0, 0]) bracket();
}

if (part == "assembly")      assembly();
if (part == "clamp_right")   clamp_right();
if (part == "clamp_left")    clamp_left();
if (part == "bracket")       bracket_print();
if (part == "jaw")           moving_jaw(rec_len);
if (part == "knob")          knob();
if (part == "receiver_test") translate([0, 0, 5]) receiver_test();
if (part == "jaw_test")      moving_jaw(20);
if (part == "print_all") {
    clamp_right();
    translate([-15, 0, 0]) clamp_left();
    translate([140, -R_out - 50, 0]) bracket_print();
    translate([60, 60, 0]) moving_jaw(rec_len);
    translate([-80, 70, 0]) knob();
}
