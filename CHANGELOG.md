### 0.8.569 / 2014-12-03

* ByteArray#to_s forces default encoding for platform
  * fixes rare bug in which trying to print binary data nested within
    decoded binary data raises an encoding incompatibility error.

### 0.8.567 / 2014-09-21

* restore newline suppression when writing in json mode
* helpful error message when nested object has no handler

### 0.8.560 (java platform only) / 2014-09-12

* Bump dependency on transit-java to 0.8.269
  * fixes bug which turned an empty set into an array

### 0.8.552 (java platform only) / 2014-09-12

* Support JRuby!

### 0.8.539 / 2014-09-05

* Support special numbers (NaN, INF, -INF)

### 0.8.467 / 2014-07-22

* Initial release