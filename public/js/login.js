// login.js

document.getElementById("loginForm").addEventListener("submit", function(e) {
  e.preventDefault();

  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;

  firebase.auth().signInWithEmailAndPassword(email, password)
    .then((userCredential) => {
      const user = userCredential.user;

      // Fetch role from Firestore
      return firebase.firestore()
        .collection("roles")
        .doc(user.uid) // UID from Firebase Auth
        .get();
    })
    .then((doc) => {
      if (doc.exists) {
        const role = doc.data().role;
        if (role === "admin") {
          window.location.href = "admin-dashboard.html";
        } else if (role === "waiter") {
          window.location.href = "waiter-order.html";
        } else {
          alert("Unauthorized role");
        }
      } else {
        alert("Role not found");
      }
    })
    .catch((error) => {
      console.error("Login error:", error);
      alert(error.message);
    });
});
