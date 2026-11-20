class_name VanchiArt
extends RefCounted

static func hull_point(t: float, row: float, side: float, inset: float = 0.0) -> Vector3:
    var fullness = pow(maxf(0.0,1.0-t*t),.67)
    var width = fullness*lerpf(.17,.78,row)-inset*fullness
    var keel = -.36+pow(absf(t),4.5)*.77
    return Vector3(width*side,keel+pow(row,1.7)*(.49+.10*absf(t)),t*3.28)

static func build(root: Node3D):
    var wood = [Color("42302a"),Color("60412c"),Color("775036"),Color("926441")]
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1,1]:
        for row in 4:
            for i in 40:
                var t = -1.0+i/20.0
                var next = t+.05
                for inset in [0.0,.038]:
                    var points = [hull_point(t,row/4.0,side,inset),hull_point(next,row/4.0,side,inset),
                        hull_point(t,(row+1)/4.0,side,inset),hull_point(next,(row+1)/4.0,side,inset)]
                    for j in [0,1,2,1,3,2]:
                        st.set_color(wood[row].lightened(.025*sin(i*1.8)))
                        st.set_uv(Vector2((t+1.0)*5.0,row/4.0))
                        st.add_vertex(points[j])
    st.generate_normals()
    var material = ShaderMaterial.new()
    material.shader = preload("res://shaders/boat_wood.gdshader")
    Craft.cache["vanchi_hull"] = material
    Craft.mesh(root,st.commit(),Vector3.ZERO,material)
    var trim = Craft.mat("b18a54")
    var dark = Craft.mat("513c2b")
    var brass = Craft.mat("c19a57",.35)
    # Continuous raised gunwales follow the sheer; curved stems lift at each end.
    for side in [-1,1]:
        for i in 40:
            var t = -1.0+i/20.0
            Craft.beam(root,hull_point(t,1.0,side),hull_point(t+.05,1.0,side),.035,trim)
    for t in [-1,1]:
        var tip = hull_point(t,1.0,1)
        Craft.beam(root,tip-Vector3(0,.25,t*.10),tip+Vector3(0,.20,t*.12),.047,dark)
        Craft.sphere(root,tip+Vector3(0,.20,t*.12),Vector3(.10,.13,.12),brass)
    # Floorboards, exposed ribs, and three slatted thwarts.
    for i in 5:
        Craft.box(root,Vector3((i-2)*.135,-.255,0),Vector3(.123,.055,4.38),Craft.mat("806045" if i%2 else "735238"))
    for z in [-2.1,-1.4,-.7,0,.7,1.4,2.1]:
        var t = z/3.28
        for side in [-1,1]:
            for r in 3:
                Craft.beam(root,hull_point(t,r/3.0,side,.058),hull_point(t,(r+1)/3.0,side,.058),.021,trim)
    for z in [-1.4,.46,1.65]:
        var width = hull_point(z/3.28,1.0,1).x*1.85
        for i in 3:
            Craft.box(root,Vector3(0,.15,z+(i-1)*.09),Vector3(width,.065,.078),trim)
    # Small cargo bundle, rope coils, and brass fastenings keep the silhouette local.
    var cloth = Craft.mat("a64732")
    var roll = Craft.cylinder(root,Vector3(-.12,.28,1.75),.14,.72,cloth)
    roll.rotation.z = PI/2
    for x in [-.37,.10]:
        var ring = TorusMesh.new()
        ring.inner_radius = .139
        ring.outer_radius = .155
        ring.rings = 16
        ring.ring_segments = 6
        var tie = Craft.mesh(root,ring,Vector3(x,.28,1.75),Craft.mat("bda075"))
        tie.rotation.z = PI/2
    for i in 4:
        var rope = TorusMesh.new()
        rope.inner_radius = .105+i*.028
        rope.outer_radius = .121+i*.028
        rope.rings = 24
        rope.ring_segments = 5
        Craft.mesh(root,rope,Vector3(.02,-.16,-2.05),Craft.mat("b5a076"))
    AvatarArt.bake_joint(root)

static func paddle(root: Node3D):
    var shaft = Craft.mat("b38a54")
    Craft.beam(root,Vector3(0,.40,0),Vector3(0,-1.17,0),.021,shaft)
    AvatarArt.ellipsoid(root,Vector3(0,-1.36,0),Vector3(.235,.58,.047),Craft.mat("795034"))
    Craft.beam(root,Vector3(-.095,.40,0),Vector3(.095,.40,0),.023,shaft)
    for y in [-.07,-.035,0,.035]:
        Craft.cylinder(root,Vector3(0,y,0),.025,.015,Craft.mat("594332"))
    AvatarArt.bake_joint(root)
