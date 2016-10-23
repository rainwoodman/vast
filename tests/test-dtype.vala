using Vast;

int main (string[] args) {

    Vast.TypeFactory.init();

    message("hello");
    var dtype_simple = new Vast.TypeDescr(8);
    message("dtype = %s", dtype_simple.to_string());
 
    var dtype_shape = new Vast.TypeDescr(8, new size_t[] {1, 2, 3});
    message("dtype = %s", dtype_shape.to_string());

    string [] strings = {"f4", "f8"};

    foreach(var str in strings) {
        var dtype = Vast.dtype(str);
        message("dtype = %s", dtype.to_string());
    }

    return 0;

}
