
    q         = require 'q'
    redis     = require 'node-redis'
    client    = redis.createClient()
    microtime = require 'microtime'

These need to get obtained from the `promise-settings` module:

    required_trust   = 0.51
    required_quality = 0.90

This function lists all the catagories to be ignored

    ignore = (cat) ->
      cat?.indexOf('Shopping') == 0                           or
      cat?.indexOf('Retailer') >= 0                           or 
      cat == 'Internet_and_Telecom/Social_Network'            or
      cat == 'Career_and_Education/Universities_and_Colleges' or
      cat == 'Reference/Dictionaries_and_Encyclopedias'       or
      cat == 'Finance/Insurance'                              or
      cat == 'Internet_and_Telecom/Ad Network'                or
      cat == 'Internet_and_Telecom/Chats and Forums'          or
      cat == 'Internet_and_Telecom/Domain Names and Register' or
      cat == 'Internet_and_Telecom/Email'                     or
      cat == 'Internet_and_Telecom/File_Sharing'              or
      cat == 'Internet_and_Telecom/Mobile_Developers'         or
      cat == 'Internet_and_Telecom/Online_Marketing'          or
      cat == 'Internet_and_Telecom/Search_Engine'             or
      cat == 'Internet_and_Telecom/Social_Network'            or
      cat == 'Internet_and_Telecom/Telecommunications'

    module.exports =
      
      add_author: (author, article, source) ->
        time        = microtime.now()
        transaction = client.multi()
        deferred    = q.defer()

        transaction
          .zincrby 'authors:counts',             1,    author
          .zincrby "authors:#{author}:sources",  1,    source
          .zadd    "authors:#{author}:articles", time, article
          .exec (err) ->
            if err?
              deferred.reject err
            else
              deferred.resolve()

        deferred.promise

I'd like this method to compute averages for trustable and quality scores - and maybe child safe.

      add_source: (guid, details) ->
        time        = microtime.now()
        transaction = client.multi()
        deferred    = q.defer()

        if details.trustable > required_trust and details.quality > required_quality and ignore(details.category) == false

          transaction
            .zadd  'categories',           time, details.category
            .zadd  "#{category}:sources",  time, guid
            .zadd  'sources:gold',         time, guid
            .hmset "sources:gold:#{guid}", details
        else
          transaction
            .hmset "sources:rejected:#{guid}", details
            .zadd  'sources:rejected',         time, guid

        transaction
          .hincrby 'sources', 'count', 1
          .exec (err) ->
            if err?
              deferred.reject err
            else
              deferred.resolve()

        deferred.promise
