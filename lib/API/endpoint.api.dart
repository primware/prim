class Base {
  static bool prod = false;
  static bool local = true;
  static String title = prod ? 'Prod' : 'Test';

  static String baseURL = local
      ? 'https://localhost:8480'
      : prod
          ? 'https://idempiere.com'
          : 'https://testidempiere.com';
}

class EndPoints {
  static String postUserAuth = '${Base.baseURL}/api/v1/auth/tokens';

  static String request = '${Base.baseURL}/api/v1/models/R_Request';

  static String user = '${Base.baseURL}/api/v1/models/AD_User';

  static String partner = '${Base.baseURL}/api/v1/models/C_BPartner';

  static String rol = '${Base.baseURL}/api/v1/models/AD_User_Roles';

  static String salesRep =
      '${Base.baseURL}/api/v1/models/C_BPartner?\$expand=AD_User(\$select=Name)&\$select=Name,IsSalesRep&\$filter=IsSalesRep eq true';

  static String customStateSales =
      '${Base.baseURL}/api/v1/models/AMP_CustomStates?\$expand=AMP_CustomStates_Info(\$select=Name,Description)&\$select=Name,IsSOTrx,IsInTransit,Description&\$filter=IsSOTrx eq \'SO\'';

  static String getOrganizationsAfterLogin =
      '${Base.baseURL}/api/v1/models/AD_Org';

  static String currency = '${Base.baseURL}/api/v1/models/C_Currency';

  static String country = '${Base.baseURL}/api/v1/models/C_Country';

  static String initialclientsetup =
      '${Base.baseURL}/api/v1/processes/initialclientsetup';
}

class GetCustomerData {
  final String id;

  GetCustomerData({required this.id});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/C_BPartner?\$expand=AD_User(\$select=EMail,Phone,Phone2,Comments,Birthday,AD_Image_ID)&\$select=Value,Name,Name2,TaxID,Description,SalesRep_ID&\$filter=Value eq \'$id\' or TaxID eq \'$id\'';
}

class GetAttachmentProduct {
  final int recordID;

  GetAttachmentProduct({required this.recordID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/AD_Attachment?\$filter=AD_Table_ID eq 208 and record_id eq $recordID';
}

class GetUserData {
  final int adUserID;

  GetUserData({required this.adUserID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/AD_User?\$filter=AD_User_ID eq $adUserID';
}

class GetRol {
  final int clientID;

  GetRol({required this.clientID});

  String get endPoint => '${Base.baseURL}/api/v1/auth/roles?client=$clientID';
}

class GetOrganization {
  final int rolID;
  final int clientID;
  GetOrganization({required this.rolID, required this.clientID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/auth/organizations?client=$clientID&role=$rolID';
}
