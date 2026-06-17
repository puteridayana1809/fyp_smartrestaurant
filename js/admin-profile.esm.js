import {
  EmailAuthProvider,
  reauthenticateWithCredential,
  updatePassword,
  updateProfile
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";

const STORAGE_PREFIX = "bsdsAdminProfile:";

function storageKey(user) {
  return `${STORAGE_PREFIX}${user?.uid || "guest"}`;
}

function readProfile(user) {
  try {
    return JSON.parse(localStorage.getItem(storageKey(user))) || {};
  } catch {
    return {};
  }
}

function saveProfile(user, profile) {
  localStorage.setItem(storageKey(user), JSON.stringify(profile));
}

function getDisplayName(user, profile) {
  return profile.name || user?.displayName || user?.email || user?.uid || "Admin";
}

function getPhotoSource(user, profile) {
  return profile.photoData || user?.photoURL || "";
}

function getInitial(name) {
  return (name || "A").trim().charAt(0).toUpperCase() || "A";
}

function renderAvatar(avatarEl, name, photoURL) {
  if (!avatarEl) return;

  if (photoURL) {
    avatarEl.innerHTML = `<img src="${photoURL}" alt="Admin profile photo">`;
    return;
  }

  avatarEl.textContent = getInitial(name);
}

function ensureModal() {
  let modal = document.getElementById("adminProfileModal");
  if (modal) return modal;

  modal = document.createElement("div");
  modal.className = "modal fade admin-profile-modal";
  modal.id = "adminProfileModal";
  modal.tabIndex = -1;
  modal.setAttribute("aria-hidden", "true");
  modal.innerHTML = `
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <form id="adminProfileForm">
          <div class="modal-header">
            <h5 class="modal-title"><i class="fas fa-user-pen me-2"></i>Edit Admin Profile</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <div class="admin-profile-editor">
              <div class="admin-profile-photo">
                <div class="admin-profile-preview" id="adminProfilePreview">A</div>
                <label class="btn btn-outline-success btn-sm mb-0" for="adminProfileFile">
                  <i class="fas fa-image me-2"></i>Choose Photo
                </label>
                <input class="d-none" id="adminProfileFile" type="file" accept="image/*">
                <button type="button" class="btn btn-link btn-sm text-danger p-0" id="adminProfileRemovePhoto">Remove photo</button>
              </div>
              <div class="admin-profile-fields">
                <div class="mb-3">
                  <label class="form-label" for="adminProfileName">Display name</label>
                  <input class="form-control" id="adminProfileName" autocomplete="name" placeholder="Admin">
                </div>
                <div class="mb-3">
                  <label class="form-label" for="adminProfileRole">Role label</label>
                  <input class="form-control" id="adminProfileRole" placeholder="Admin">
                </div>
                <div class="mb-0">
                  <label class="form-label" for="adminProfileEmail">Login email</label>
                  <input class="form-control" id="adminProfileEmail" readonly>
                </div>
              </div>
            </div>
            <div class="admin-password-panel">
              <div class="admin-password-title">
                <i class="fas fa-lock"></i>
                <span>Change Password</span>
              </div>
              <div class="row g-3">
                <div class="col-12">
                  <label class="form-label" for="adminCurrentPassword">Current password</label>
                  <input class="form-control" id="adminCurrentPassword" type="password" autocomplete="current-password">
                </div>
                <div class="col-12 col-md-6">
                  <label class="form-label" for="adminNewPassword">New password</label>
                  <input class="form-control" id="adminNewPassword" type="password" autocomplete="new-password">
                </div>
                <div class="col-12 col-md-6">
                  <label class="form-label" for="adminConfirmPassword">Confirm password</label>
                  <input class="form-control" id="adminConfirmPassword" type="password" autocomplete="new-password">
                </div>
              </div>
              <div class="small text-muted mt-2">Leave password fields empty if you only want to update profile details.</div>
            </div>
            <input type="hidden" id="adminProfilePhotoData">
            <div class="small text-muted">Uploaded photo is saved on this browser for this admin account.</div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="submit" class="btn btn-success">
              <i class="fas fa-save me-2"></i>Save
            </button>
          </div>
        </form>
      </div>
    </div>
  `;
  document.body.appendChild(modal);
  wireModalPreview(modal);
  return modal;
}

function updateModalPreview(modal, name, photoSource) {
  const preview = modal.querySelector("#adminProfilePreview");
  if (!preview) return;

  if (photoSource) {
    preview.innerHTML = `<img src="${photoSource}" alt="Admin profile preview">`;
    return;
  }

  preview.textContent = getInitial(name);
}

function wireModalPreview(modal) {
  const nameInput = modal.querySelector("#adminProfileName");
  const photoDataInput = modal.querySelector("#adminProfilePhotoData");
  const fileInput = modal.querySelector("#adminProfileFile");
  const removeButton = modal.querySelector("#adminProfileRemovePhoto");

  nameInput?.addEventListener("input", () => {
    updateModalPreview(modal, nameInput.value, photoDataInput.value);
  });

  fileInput?.addEventListener("change", () => {
    const file = fileInput.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      photoDataInput.value = String(reader.result || "");
      updateModalPreview(modal, nameInput.value, photoDataInput.value);
    };
    reader.readAsDataURL(file);
  });

  removeButton?.addEventListener("click", () => {
    photoDataInput.value = "";
    if (fileInput) fileInput.value = "";
    updateModalPreview(modal, nameInput.value, "");
  });
}

function ensureEditButton(userInfo) {
  if (!userInfo || userInfo.querySelector(".profile-edit-action")) return;

  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "profile-edit-action";
  btn.title = "Edit admin profile";
  btn.setAttribute("aria-label", "Edit admin profile");
  btn.innerHTML = '<i class="fas fa-pen-to-square"></i>';
  userInfo.appendChild(btn);
}

export function setupAdminProfile(user) {
  if (!user) return;

  const profile = readProfile(user);
  const name = getDisplayName(user, profile);
  const role = profile.role || "Admin";
  const photoSource = getPhotoSource(user, profile);

  const whoami = document.getElementById("whoami");
  const avatar = document.getElementById("userAvatar");
  const roleEl = document.querySelector(".sidebar-footer .user-details .role");
  const userInfo = document.querySelector(".sidebar-footer .user-info");

  if (whoami) whoami.textContent = name;
  if (roleEl) roleEl.textContent = role;
  renderAvatar(avatar, name, photoSource);
  ensureEditButton(userInfo);

  if (!userInfo || userInfo.dataset.profileReady === "true") return;
  userInfo.dataset.profileReady = "true";

  userInfo.addEventListener("click", (event) => {
    if (event.target.closest("#logoutBtn")) return;

    const latest = readProfile(user);
    const latestName = getDisplayName(user, latest);
    const latestPhotoSource = getPhotoSource(user, latest);
    const modalEl = ensureModal();
    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);

    modalEl.querySelector("#adminProfileName").value = latestName;
    modalEl.querySelector("#adminProfileRole").value = latest.role || "Admin";
    modalEl.querySelector("#adminProfileEmail").value = user.email || user.uid || "";
    modalEl.querySelector("#adminProfilePhotoData").value = latest.photoData || "";
    modalEl.querySelector("#adminCurrentPassword").value = "";
    modalEl.querySelector("#adminNewPassword").value = "";
    modalEl.querySelector("#adminConfirmPassword").value = "";
    updateModalPreview(modalEl, latestName, latestPhotoSource);
    modal.show();
  });

  document.addEventListener("submit", async (event) => {
    if (event.target?.id !== "adminProfileForm") return;
    event.preventDefault();

    const modalEl = document.getElementById("adminProfileModal");
    const nextProfile = {
      name: modalEl.querySelector("#adminProfileName").value.trim(),
      role: modalEl.querySelector("#adminProfileRole").value.trim() || "Admin",
      photoData: modalEl.querySelector("#adminProfilePhotoData").value.trim()
    };

    const currentPassword = modalEl.querySelector("#adminCurrentPassword").value;
    const newPassword = modalEl.querySelector("#adminNewPassword").value;
    const confirmPassword = modalEl.querySelector("#adminConfirmPassword").value;

    if (newPassword || confirmPassword || currentPassword) {
      if (!user.email) {
        alert("Password change needs an email login account.");
        return;
      }

      if (!currentPassword) {
        alert("Please enter your current password.");
        return;
      }

      if (newPassword.length < 6) {
        alert("New password must be at least 6 characters.");
        return;
      }

      if (newPassword !== confirmPassword) {
        alert("New password and confirm password do not match.");
        return;
      }

      try {
        const credential = EmailAuthProvider.credential(user.email, currentPassword);
        await reauthenticateWithCredential(user, credential);
        await updatePassword(user, newPassword);
      } catch (error) {
        alert("Password update failed: " + error.message);
        return;
      }
    }

    saveProfile(user, nextProfile);

    try {
      await updateProfile(user, {
        displayName: nextProfile.name || null,
        photoURL: null
      });
    } catch (error) {
      console.warn("Firebase profile update skipped:", error);
    }

    setupAdminProfile(user);
    bootstrap.Modal.getOrCreateInstance(modalEl).hide();
  });
}
