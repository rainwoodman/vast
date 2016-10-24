Topics
------

- Components

  - dense array operations on a CPU device

  - building a computation graph

  - forward execution : serial ; distributed ; devices

  - tape and backward gradient execution

  - optimizers

- Data model

  - TypeDescr, Array, UFunc

  - (Graph) Function, Variable, AnonymousVariable (for intermediate results, names are automatic)

  - bind graph to device: Function -> UFunc, Variable -> Array

  - after binding to a device: Evaluation, Tape;

  - Gradient transformation (needs a tape and graph)

- Why a parallel typing system ? cann't we reuse the one from GLib? Complications

  - Record types

  - interpolability with Python

  - devices?

- Computing Graph from Lazy functions; interfaces on UFunc?

- broadcast groups in 'in' arguments of UFunc.

