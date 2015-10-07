# Read files from Azure in Spark

In this example, we will use the `NativeAzureFileSystem` from Hadoop 2.7
in order to list files in Azure storage, and do some things with the files.

## Getting Started

For this example, I used Spark 1.4.1 and Hadoop 2.7.1, running on Windows 7.
You can download the distributions of those packages from their respective
websites, and inspect `start-spark.cmd` and `hadoop.cmd` to repeat the method
I used to launch the spark shell.

### Pre-requisites

This example requires a storage account in Azure, and a blob container in said
account. Also, override the default Spark and Hadoop settings with those in
the respective files in the `override/` directory, subsituting local settings
where relevant.

For sample data, I already had a previous blob container initialized from
Azure HDInsight, so sample text files already existed in the container, under
the `/HdiSamples/` path.

### Gotchas

Once `core-site.xml` is properly configured, running `hadoop fs -ls /` from the
command line should succeed. Alternatively (or without setting `fs.defaultFS`),
running `hadoop fs -ls wasb://mycontainer@myaccount.blob.core.windows.net/`
should succeed. However, out of the box, Hadoop did not properly map the `wasb(s)`
URIs to the correct filesystem implementation. To fix this, I had to ensure that
`hadoop-2.7.1/share/hadoop/tools/lib/*` was in the `HADOOP_CLASSPATH`.

## Listing Files In Azure Blob Storage

First, we should be able to use a handful of classes from `org.apache.hadoop.fs` to
list the files recursively. The native format returned by `listFiles`,
`LocatedFileStatus`, is not serializable, so to have more fun with the results, we
can just keep the plain bits we care about - the path. The transformation `toUri`
lets us get just the path component and discard the `wasbs://....` bits.

With the path names in a list, we can start to do fun things like use the `SparkContext`
to make an `RDD` out out them, filtering our results to only those in the samples
directory.

```
var (fs, samples) = {
    import org.apache.hadoop.fs.{ FileSystem, Path }
    import org.apache.spark.rdd._
    var fs = FileSystem.get(sc.hadoopConfiguration)

    var it = fs.listFiles(new Path("/"), true)

    var l = List[String]()
    while (it.hasNext) { val e = it.next; l = l.union(Seq(e.getPath.toUri.getPath)); }

    var rdd = sc.makeRDD(l)
    var samples = rdd.filter(_.startsWith("/HdiSamples"))
    (fs, samples)
}
```

Next up, we try to load up the text files like normal through `sc.textFile`. However,
Spark doesn't like us trying to make an RDD of RDDs. Try the following on for size to
see what I mean.

```
var (samplesRdds) = {
    samples.map(s => (s, sc.textFile(s)))
}
```

Perhaps if we put these into a list, first. Let's try to get a list of RDDs, and keep
the original filename around in a tuple.

```
var (samplesRdds) = {
    import org.apache.spark.rdd._
    var l = List[(String, RDD[String])]()
    samples.foreach(s => { l = l.union(Seq((s, sc.textFile(s)))) })
    (l)
}
```

Still not quite right. Spark appears to be complaining about serialization and closures.

This time, we'll use `collect` to execute the closure without needing to serialize the
task, (operating on an `Array` instead of an `RDD`):

```
var (samplesRdds) = {
    import org.apache.spark.rdd._
    var l = List[(String, RDD[String])]()
    samples.collect.foreach(s => { l = l.union(Seq((s, sc.textFile(s)))) })
    (l.toMap)
}
```

And now we have a map of our sample filenames, to RDDs of their file contents. Yay!
