using Vast;

int main (string[] args) {

    Vast.init();

    message("hello");
    var sin = ufunc("sin");
    var mul = ufunc("mul");

    var src = range(0, 10, 1, dtype("f8"));
    var factor = zeros({}, dtype("f8"));
    var dest = empty({10, });

    * (double*) src.get_dataptr({ 1, }) = 3.0;

    * (double*) factor.get_dataptr() = Math.PI / 10.0;

    /* scale src by factor */
    mul.apply({src, factor}, {src});

    /* calculate sin */
    sin.apply({src}, {dest});
    message("sin");
    message("%s", src.to_string());
    message("%s", dest.to_string());

    mul.apply({dest, factor}, {dest});
    message("mul");
    message("%s", factor.to_string());
    message("%s", src.to_string());
    message("%s", dest.to_string());

    return 0;

}
