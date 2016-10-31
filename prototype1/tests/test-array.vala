using Vast;

int main (string[] args) {

    Vast.init();

    message("hello");

    var a = new Vast.Array.range(dtype("f4"), 0, 10);
    message(a.to_string());

    var b = a.cast(dtype("f8"));
    message(b.to_string());
                
    var c1 = a.view( { ArraySlice.every(2) });
    message(c1.to_string());

    var c2 = a.view( { ArraySlice.every(-1) });
    message(c2.to_string());

    var c3 = a.view( { ArraySlice.till(5, -1) });
    message(c3.to_string());

    var c4 = a.view( { ArraySlice.till(5) });
    message(c4.to_string());

    var c5 = a.view( { ArraySlice.from(5, -1) });
    message(c5.to_string());

    var c6 = a.view( { ArraySlice.from(5),});

    message(c6.to_string());

    var d = a.reshape(new size_t[] {2, 5});
    message(d.to_string());

    var d1 = d.view({ArraySlice.every(-1), ArraySlice.every(1)});
    message(d1.to_string());

    return 0;
}
