### 0.8.591 / 2015-05-03

* Bump lock_jar dependency to ~> 0.12.0 #17

### 0.8.588 / 2015-04-10

* Update to transit-java-0.8.287 for json int boundary fix in JRuby

### 0.8.586 / 2015-03-13

* Add handler caching for MRI
* Bump to transit-java-0.8.285 for handler caching in JRuby

### 0.8.572 / 2015-01-15

* Marshal int map keys as ints in msgpack

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
