using Vast;

int main (string[] args) {

    Vast.init();

    message("hello");
    var sin = ufunc("sin");
    var mul = ufunc("mul");

    var src = range(0, 10, 1, dtype("f8"));
    var factor = zeros(new size_t [0], dtype("f8"));

    * (double*) factor.get_dataptr() = 3.0;

    var dest = empty({(size_t)10, });

    sin.apply({src}, {dest});
    message("sin");
    message("%s", src.to_string());
    message("%s", dest.to_string());

    mul.apply({src, factor}, {dest});
    message("mul");
    message("%s", factor.to_string());
    message("%s", src.to_string());
    message("%s", dest.to_string());

    return 0;

}
