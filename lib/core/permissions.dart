class Permissions {

  static bool canAccess(String role, String module) {

    // 🔥 ADMIN ACCEDE A TODO
    if (role == "admin") return true;

    // 💰 CAJERO SOLO POS
    if (role == "cashier") {
      return module == "POS";
    }

    // 📊 MANAGER (si lo usas después)
    if (role == "manager") {
      return module == "POS" || module == "REPORTS";
    }

    return false;
  }
}