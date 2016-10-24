using Vast;

int main (string[] args) {

    Vast.init();

    message("hello");
    var sin = ufunc("sin");
    var src = new Vast.Array.range(dtype("f8"), 0, 10);
    var dest = new Vast.Array.empty(dtype("f8"), {(size_t)10, });

    sin.apply({src}, {dest});

    message("%s", src.to_string());
    message("%s", dest.to_string());
    return 0;

}
