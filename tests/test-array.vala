using Vast;

int main (string[] args) {

    Vast.init();

    message("hello");

    var a = new Vast.Array.range(dtype("f4"), 0, 10);
    message(a.to_string());

    var b = a.cast(dtype("f8"));
    message(b.to_string());
                
    var c = a.get_item(new Vast.Slice [] { Vast.Slice(0, 1) });
    message(c.to_string());

    return 0;
}
