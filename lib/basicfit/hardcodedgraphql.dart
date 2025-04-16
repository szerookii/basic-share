const HARDCODED_GRAPHQL_REQUEST = r'''
{"operationName":"getClubByIds","variables":{"where":{"clubId":"%CLUB_ID%"},"locale":"fr","limit":1},"query":"fragment ClubFields on Club {\n  busynessData\n}\n\nquery getClubByIds($locale: String, $where: ClubFilter!, $limit: Int, $skip: Int) {\n  clubCollection(locale: $locale, where: $where, limit: $limit, skip: $skip) {\n    total\n    items {\n      ...ClubFields\n      __typename\n    }\n    __typename\n  }\n}\n"}
''';
