The examples/ dir includes some scripts you can use to try things out.

Assuming you have the transit repo in a sibling directory to
transit-ruby, try this from the transit-ruby root:

```
example/cat-source-files.rb ../transit/simple-examples/*.json | example/read-write.rb
```

If you want to compare input to output, try this:

```
rm tmp/source.txt tmp/target.txt
example/cat-source-files.rb ../transit/simple-examples/*.json >> tmp/source.txt
example/cat-source-files.rb ../transit/simple-examples/*.json | example/read-write.rb >> tmp/target.txt
diff tmp/source.txt tmp/target.txt
```
