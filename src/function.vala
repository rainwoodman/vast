namespace Vast {


public delegate void FunctionImplementation (
            [CCode (array_length=false)]
            void * [] ptrin,
            [CCode (array_length=false)]
            void * [] ptrout);

public struct Signature {
    /* FIXME: define equal functions */
    [CCode (array_length=false)]
    Type [] typein;
}

public class Implementation {
    /* Because a delegate can't go into a hashtable */ 
    FunctionImplementation impl;
}

public class Function : Object {
    public int nin; 
    public int nout; 

    HashTable <Signature?, Implementation?> table;
    
    public static void register(Type [] typein, Implementation impl)
    {

    }
}

}
