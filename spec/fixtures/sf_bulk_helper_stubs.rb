module Remi::SfBulkHelperStubs
  extend self

  def contact_query
    <<-EOT
    SELECT
      Id,
      Student_ID__c,
      RecordTypeId,
      FirstName,
      LastName
    FROM
      Contact
    WHERE
      AccountId = '001G000000ncxb8IAA'
    LIMIT 5
    EOT
  end

  def delete_raw_result
    {
      "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
      "id" => [
        "750g0000004iys2AAA"
      ],
      "operation" => [
        "delete"
      ],
      "object" => [
        "Contact"
      ],
      "createdById" => [
        "005A0000000eJ57IAE"
      ],
      "createdDate" => [
        "2017-01-25T20:06:30.000Z"
      ],
      "systemModstamp" => [
        "2017-01-25T20:06:30.000Z"
      ],
      "state" => [
        "Closed"
      ],
      "concurrencyMode" => [
        "Parallel"
      ],
      "contentType" => [
        "XML"
      ],
      "numberBatchesQueued" => [
        "1"
      ],
      "numberBatchesInProgress" => [
        "0"
      ],
      "numberBatchesCompleted" => [
        "0"
      ],
      "numberBatchesFailed" => [
        "0"
      ],
      "numberBatchesTotal" => [
        "1"
      ],
      "numberRecordsProcessed" => [
        "0"
      ],
      "numberRetries" => [
        "0"
      ],
      "apiVersion" => [
        "32.0"
      ],
      "numberRecordsFailed" => [
        "0"
      ],
      "totalProcessingTime" => [
        "0"
      ],
      "apiActiveProcessingTime" => [
        "0"
      ],
      "apexProcessingTime" => [
        "0"
      ],
      "batches" => [
        {
          "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
          "id" => [
            "751g0000002ozU5AAI"
          ],
          "jobId" => [
            "750g0000004iys2AAA"
          ],
          "state" => [
            "Completed"
          ],
          "createdDate" => [
            "2017-01-25T20:06:31.000Z"
          ],
          "systemModstamp" => [
            "2017-01-25T20:07:19.000Z"
          ],
          "numberRecordsProcessed" => [
            "1"
          ],
          "numberRecordsFailed" => [
            "0"
          ],
          "totalProcessingTime" => [
            "684"
          ],
          "apiActiveProcessingTime" => [
            "459"
          ],
          "apexProcessingTime" => [
            "74"
          ],
          "response" => [
            {
              "id" => [
                "003g000001LVMx3AAH"
              ],
              "success" => [
                "true"
              ],
              "created" => [
                "false"
              ]
            }
          ]
        }
      ]
    }
  end

  def contact_query_raw_result
    {
      "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
      "id" => [
        "75016000004Ic1OAAS"
      ],
      "operation" => [
        "query"
      ],
      "object" => [
        "Contact"
      ],
      "createdById" => [
        "005G0000005shkrIAA"
      ],
      "createdDate" => [
        "2015-11-07T00:30:25.000Z"
      ],
      "systemModstamp" => [
        "2015-11-07T00:30:25.000Z"
      ],
      "state" => [
        "Closed"
      ],
      "concurrencyMode" => [
        "Parallel"
      ],
      "contentType" => [
        "XML"
      ],
      "numberBatchesQueued" => [
        "0"
      ],
      "numberBatchesInProgress" => [
        "0"
      ],
      "numberBatchesCompleted" => [
        "1"
      ],
      "numberBatchesFailed" => [
        "0"
      ],
      "numberBatchesTotal" => [
        "1"
      ],
      "numberRecordsProcessed" => [
        "5"
      ],
      "numberRetries" => [
        "0"
      ],
      "apiVersion" => [
        "32.0"
      ],
      "numberRecordsFailed" => [
        "0"
      ],
      "totalProcessingTime" => [
        "0"
      ],
      "apiActiveProcessingTime" => [
        "0"
      ],
      "apexProcessingTime" => [
        "0"
      ],
      "batches" => [
        {
          "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
          "id" => [
            "751160000065e2BAAQ"
          ],
          "jobId" => [
            "75016000004Ic1OAAS"
          ],
          "state" => [
            "Completed"
          ],
          "createdDate" => [
            "2015-11-07T00:30:25.000Z"
          ],
          "systemModstamp" => [
            "2015-11-07T00:30:26.000Z"
          ],
          "numberRecordsProcessed" => [
            "5"
          ],
          "numberRecordsFailed" => [
            "0"
          ],
          "totalProcessingTime" => [
            "0"
          ],
          "apiActiveProcessingTime" => [
            "0"
          ],
          "apexProcessingTime" => [
            "0"
          ],
          "response" => [
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "003G000001cKYaUIA4",
                "003G000001cKYaUIA4"
              ],
              "Student_ID__c" => [
                "FJD385628"
              ],
              "RecordTypeId" => [
                "012G0000000yEClIAM"
              ],
              "FirstName" => [
                "Alicia"
              ],
              "LastName" => [
                "Quantico"
              ]
            },
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "003G000000cbYU0IAO",
                "003G000000cbYU0IAO"
              ],
              "Student_ID__c" => [
                "BHS0375638"
              ],
              "RecordTypeId" => [
                "012G0000000yEClIAM"
              ],
              "FirstName" => [
                "Jason"
              ],
              "LastName" => [
                "Hockeymask"
              ]
            },
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "003G000001cQYWyIAO",
                "003G000001cQYWyIAO"
              ],
              "Student_ID__c" => [
                "BHS83561365"
              ],
              "RecordTypeId" => [
                "012G0000000yEClIAM"
              ],
              "FirstName" => [
                "Marlin"
              ],
              "LastName" => [
                "Jones"
              ]
            },
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "003G000001cKYLrIAO",
                "003G000001cKYLrIAO"
              ],
              "Student_ID__c" => [
                "BHS3656616363"
              ],
              "RecordTypeId" => [
                "012G0000000yEClIAM"
              ],
              "FirstName" => [
                "Alberto"
              ],
              "LastName" => [
                "Einsteinium"
              ]
            },
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "002G000001cKYSzIAl",
                "002G000001cKYSzIAl"
              ],
              "Student_ID__c" => [
                "BHS338238855656"
              ],
              "RecordTypeId" => [
                "012G0000000yEClIAM"
              ],
              "FirstName" => [
                "Anthony"
              ],
              "LastName" => [
                "Antimony"
              ]
            }
          ]
        }
      ]
    }
  end

  def contact_query_duplicated_result
    [
      { "Id"=>"003G000001cKYaUIA4", "Student_ID__c"=>"FJD385628" },
      { "Id"=>"003G000000cbYU0IAO", "Student_ID__c"=>"FJD385628" },
      { "Id"=>"003G000001cQYWyIAO", "Student_ID__c"=>"BHS83561365" },
      { "Id"=>"003G000001cKYLrIAO", "Student_ID__c"=>"BHS3656616363" },
      { "Id"=>"002G000001cKYSzIAl", "Student_ID__c"=>"BHS338238855656" }
    ]
  end

  # Note, this is obfuscated data, do not run against the live production system.
  def contact_update_data
    [
      {
        'Id'            => '003G000002bKYOUIA4',
        'Student_ID__c' => 'FJD385628',
        'RecordTypeId'  => '012G0000000yEClIAM',
        'FirstName'     => 'Alicia',
        'LastName'      => 'Quantico',
      },
      {
        'Id'            => '003G000002caYU1IAO',
        'Student_ID__c' => 'BHS83561365',
        'RecordTypeId'  => '012G0000000yEClIAM',
        'FirstName'     => 'Jason',
        'LastName'      => 'Hockeymask',
      },
      {
        'Id'            => '003G000002cfyWyIAO',
        'Student_ID__c' => 'BHS3656616363',
        'RecordTypeId'  => '012G0000000yEClIAM',
        'FirstName'     => 'Alberto',
        'LastName'      => 'Einsteinium',
      }
    ]
  end

  def contact_update_raw_result
    {
      "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
      "id" => [
        "75016000004IfklAAC"
      ],
      "operation" => [
        "update"
      ],
      "object" => [
        "Contact"
      ],
      "createdById" => [
        "005G0000005shkrIAA"
      ],
      "createdDate" => [
        "2015-11-09T16:29:46.000Z"
      ],
      "systemModstamp" => [
        "2015-11-09T16:29:46.000Z"
      ],
      "state" => [
        "Closed"
      ],
      "concurrencyMode" => [
        "Parallel"
      ],
      "contentType" => [
        "XML"
      ],
      "numberBatchesQueued" => [
        "0"
      ],
      "numberBatchesInProgress" => [
        "0"
      ],
      "numberBatchesCompleted" => [
        "1"
      ],
      "numberBatchesFailed" => [
        "0"
      ],
      "numberBatchesTotal" => [
        "1"
      ],
      "numberRecordsProcessed" => [
        "3"
      ],
      "numberRetries" => [
        "0"
      ],
      "apiVersion" => [
        "32.0"
      ],
      "numberRecordsFailed" => [
        "0"
      ],
      "totalProcessingTime" => [
        "612"
      ],
      "apiActiveProcessingTime" => [
        "501"
      ],
      "apexProcessingTime" => [
        "379"
      ],
      "batches" => [
        {
          "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
          "id" => [
            "751160000065kWlAAI"
          ],
          "jobId" => [
            "75016000004IfklAAC"
          ],
          "state" => [
            "Completed"
          ],
          "createdDate" => [
            "2015-11-09T16:29:46.000Z"
          ],
          "systemModstamp" => [
            "2015-11-09T16:29:47.000Z"
          ],
          "numberRecordsProcessed" => [
            "3"
          ],
          "numberRecordsFailed" => [
            "0"
          ],
          "totalProcessingTime" => [
            "612"
          ],
          "apiActiveProcessingTime" => [
            "501"
          ],
          "apexProcessingTime" => [
            "379"
          ],
          "response" => [
            {
              "id" => [
                "003G000002bKYOUIA4"
              ],
              "success" => [
                "true"
              ],
              "created" => [
                "false"
              ]
            },
            {
              "id" => [
                "003G000002caYU1IAO"
              ],
              "success" => [
                "true"
              ],
              "created" => [
                "false"
              ]
            },
            {
              "id" => [
                "003G000002cfyWyIAO"
              ],
              "success" => [
                "true"
              ],
              "created" => [
                "false"
              ]
            }
          ]
        }
      ]
    }
  end

  def unable_to_lock_row
    {
      "errors" => [
        {
          "message" => [
            "unable to obtain exclusive access to this record"
          ],
          "statusCode" => [
            "UNABLE_TO_LOCK_ROW"
          ]
        }
      ],
      "success" => [ "false" ],
      "created" => [ "false" ]
    }
  end

  def contact_update_with_fail_raw_result
    update = JSON.parse(contact_update_raw_result.to_json)
    update['numberRecordsFailed'] = ['2']
    update['batches'][0]['response'][0] = unable_to_lock_row
    update['batches'][0]['response'][2] = unable_to_lock_row

    update
  end

  def contact_update_subsequent_success_raw_result
    update = JSON.parse(contact_update_raw_result.to_json)
    update['batches'][0]['response'].delete_at(1)
    update
  end
end
