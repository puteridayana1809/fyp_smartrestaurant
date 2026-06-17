import { updateProfile } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";

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
            <div class="mb-3">
              <label class="form-label" for="adminProfileName">Display name</label>
              <input class="form-control" id="adminProfileName" autocomplete="name" placeholder="Admin">
            </div>
            <div class="mb-3">
              <label class="form-label" for="adminProfileRole">Role label</label>
              <input class="form-control" id="adminProfileRole" placeholder="Admin">
            </div>
            <div class="mb-3">
              <label class="form-label" for="adminProfilePhoto">Photo URL</label>
              <input class="form-control" id="adminProfilePhoto" autocomplete="url" placeholder="https://...">
            </div>
            <div class="small text-muted">Login email is managed by Firebase Authentication.</div>
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
  return modal;
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
  const photoURL = profile.photoURL || user.photoURL || "";

  const whoami = document.getElementById("whoami");
  const avatar = document.getElementById("userAvatar");
  const roleEl = document.querySelector(".sidebar-footer .user-details .role");
  const userInfo = document.querySelector(".sidebar-footer .user-info");

  if (whoami) whoami.textContent = name;
  if (roleEl) roleEl.textContent = role;
  renderAvatar(avatar, name, photoURL);
  ensureEditButton(userInfo);

  if (!userInfo || userInfo.dataset.profileReady === "true") return;
  userInfo.dataset.profileReady = "true";

  userInfo.addEventListener("click", (event) => {
    if (event.target.closest("#logoutBtn")) return;

    const latest = readProfile(user);
    const latestName = getDisplayName(user, latest);
    const modalEl = ensureModal();
    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);

    modalEl.querySelector("#adminProfileName").value = latestName;
    modalEl.querySelector("#adminProfileRole").value = latest.role || "Admin";
    modalEl.querySelector("#adminProfilePhoto").value = latest.photoURL || user.photoURL || "";
    modal.show();
  });

  document.addEventListener("submit", async (event) => {
    if (event.target?.id !== "adminProfileForm") return;
    event.preventDefault();

    const modalEl = document.getElementById("adminProfileModal");
    const nextProfile = {
      name: modalEl.querySelector("#adminProfileName").value.trim(),
      role: modalEl.querySelector("#adminProfileRole").value.trim() || "Admin",
      photoURL: modalEl.querySelector("#adminProfilePhoto").value.trim()
    };

    saveProfile(user, nextProfile);

    try {
      await updateProfile(user, {
        displayName: nextProfile.name || null,
        photoURL: nextProfile.photoURL || null
      });
    } catch (error) {
      console.warn("Firebase profile update skipped:", error);
    }

    setupAdminProfile(user);
    bootstrap.Modal.getOrCreateInstance(modalEl).hide();
  });
}
