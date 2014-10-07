====================
Administration Tools
====================

Around loop-server code we have created some little tools that helps
administrate the server in production and troubleshooting.

Redis Tools
###########

This are tools built to administrate the Redis storage.


HawkSession expiration TTL
==========================

If you want know in how many seconds will an Hawk Session expire, you
can use the test_ttl.js tool::

    NODE_ENV=production node test_ttl.js <hawkId>

This will use the server environment configuration to read the
expiration in the REDIS database.

The output looks like::

    NODE_ENV=loadtest node ttl_hawk.js 634ecc3dc394170edbd8b2b6d3c4c4526a354b5eda8f9ed3abaeb3a89a0f83a8
    redis-cli TTL hawk.4d8535d8dfbde737e611828a690d0881d8cfd2e3eddd0dd6cb6150990bd39b5b
    expire in 2591943 seconds


Number of keys of each types
============================

If you want to have general information about the memory usage and
know how many of each keys are used, you can use::

    $ ./redis_usage.sh localhost
    [...]

    # Memory
    used_memory:592032
    used_memory_human:578.16K
    used_memory_rss:6832128
    used_memory_peak:3169928
    used_memory_peak_human:3.02M
    used_memory_lua:33792
    mem_fragmentation_ratio:11.54
    mem_allocator:jemalloc-3.4.1

    [...]

    Keys for spurl.*
    =====================
    spurl.89272fca80167430382fae1a92e4e561e186db71ba0e37178a5f4cb8ce81fa6c.e7f1f6adf79ed64b6b48b64cf63d75b81ec66f9ac615884a5736b209266048c7
    Total of keys: 5
    
    [...]


Number of callUrls per user
===========================

This script gives you the average number of callUrls per users::

    $ pip install redis hiredis
    $ python callurls_per_user.py
    average is 6.5
