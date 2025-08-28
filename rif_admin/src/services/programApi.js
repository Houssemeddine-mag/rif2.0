import { API_BASE_URL } from "./api";

export const getSessions = async () => {
  const response = await fetch(`${API_BASE_URL}/program/sessions`);
  return await response.json();
};

export const createSession = async (sessionData) => {
  const response = await fetch(`${API_BASE_URL}/program/sessions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(sessionData),
  });
  return await response.json();
};

export const updateSession = async (id, sessionData) => {
  const response = await fetch(`${API_BASE_URL}/program/sessions/${id}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(sessionData),
  });
  return await response.json();
};
