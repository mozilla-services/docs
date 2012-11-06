.. metrics_index:

==================
Metrics Collection
==================

There exists a generic metrics collection framework in Gecko applications.

Architecture
============

At the lowest level we have the concept of **measurements**. These are
effectively data structures containing strongly-typed fields with values.
These are how actual data is modeled.

Managing **measurements** are entities called **providers**. The role of a
**provider** is to emit **measurement** instances.

Managing **providers** is a **collector**. Its job is to collect and manage
**measurements** from multiple **providers**.

Measurements
============

Measurements represent obtained data. An individual measurement consists of
some metadata describing the measurement itself plus a set of fields and their
values.

The most important metadata in a measurement are the **name** and **version**.
Providers are expected to emit a known/named set of measurements. Emitted
measurements are identified primarily through their string name. Each
measurement name/type has a numeric version associated with it. The version
defines the behavior of this measurement.

Versions enforce no particular behavior in code. Instead, they allow an
implementation to self-identify with a policy that governs what versions mean.

An individual **measurement** can be encoded as JSON::

    {
        "name": "measurement-a",
        "version": 1,
        "fields": {
            "foo": "value-of-foo",
            "bar": 42
        }
    }

It consists of the following fields:

* **name** *string*: The name/type of this measurement.
* **version** *integer*: The version of this measurement.
* **fields** *object*: Mapping of field name to value.

