class AcademicData {
  static const Map<String, Map<String, Map<String, List<String>>>> regulationData = {
    "R23": {
      "AIDS": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "ML Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "DL Fundamentals", "IDS"],
        "3-1": ["EDVC", "CN", "NLP", "CV", "AI"],
        "3-2": [
          "BDA",
          "NoSQL",
          "Cloud Computing",
          "Disaster Management",
          "ML",
          "Data Visualization",
        ],
        "4-1": ["COMING_SOON"],
      },
      "CAI": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "Cloud Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "Cloud Security", "IDS"],
        "3-1": ["EDVC", "CN", "Cloud Architecture", "DevOps", "AI"],
        "3-2": [
          "Cloud Computing",
          "Data Visualization",
          "Disaster Management",
          "Operating System",
          "Data Visualization",
          "Software Testing Methodology",
        ],
        "4-1": ["COMING_SOON"],
      },
      "CSD": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "Cloud Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "Cloud Security", "IDS"],
        "3-1": ["EDVC", "CN", "Cloud Architecture", "DevOps", "AI"],
        "3-2": [
          "Cloud Computing",
          "Data Visualization",
          "Disaster Management",
          "Operating System",
          "Data Visualization",
          "Software Testing Methodology",
        ],
        "4-1": ["COMING_SOON"],
      },
      "CSM": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "Cloud Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "Cloud Security", "IDS"],
        "3-1": ["EDVC", "CN", "Cloud Architecture", "DevOps", "AI"],
        "3-2": [
          "Cloud Computing",
          "Data Visualization",
          "Disaster Management",
          "Operating System",
          "Data Visualization",
          "Software Testing Methodology",
        ],
        "4-1": ["COMING_SOON"],
      },
      "CSC": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "Cloud Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "Cloud Security", "IDS"],
        "3-1": ["EDVC", "CN", "Cloud Architecture", "DevOps", "AI"],
        "3-2": [
          "Cloud Computing",
          "Data Visualization",
          "Disaster Management",
          "Operating System",
          "Data Visualization",
          "Software Testing Methodology",
        ],
        "4-1": ["COMING_SOON"],
      },
    },
  };

  static const Map<String, List<String>> regulationBranches = {
    "R23": ["AIDS", "CAI", "CSD", "CSM", "CSC"],
  };

  static String getBranchIdPrefix(String branchName) {
    const Map<String, String> branchPrefixMap = {
      'AIDS': 'aid',
      'CAI': 'cai',
      'CSD': 'csd',
      'CSM': 'csm',
      'CSC': 'csc',
    };
    return branchPrefixMap[branchName] ?? branchName.toLowerCase();
  }
}
