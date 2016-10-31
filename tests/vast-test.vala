using Vast;

int main (string[] args) {
    message("hello");
    var a = new Vast.Array<double?>.full(1, {10,});
    message("a = %s", a.to_string());
    var b = new Vast.Array<double?>.full(1, {10,}, null, a, a.data);
    message("b = %s", b.to_string());

    for(var i = 0; i < 10; i ++) {
        a.set_scalar({i}, (double) i);
    }

    for(var i = 0; i < 10; i ++) {
        message("i = %d a[i] = %g b[i] = %g", i, a.get_scalar({i}), b.get_scalar({i}));
    }

    return 0;
}
