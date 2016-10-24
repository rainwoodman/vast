using Vast;

int main (string[] args) {

    Vast.init();

    message("hello");
    var sin = ufunc("sin");
    var src = range(0, 10, 1, dtype("f8"));
    var dest = empty({(size_t)10, });

    sin.apply({src}, {dest});

    message("%s", src.to_string());
    message("%s", dest.to_string());
    return 0;

}
