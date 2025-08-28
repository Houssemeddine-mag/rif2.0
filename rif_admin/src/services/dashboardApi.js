import { API_BASE_URL } from "./api";

export const getDashboardStats = async () => {
  const response = await fetch(`${API_BASE_URL}/dashboard/stats`);
  return await response.json();
};

export const getTopPresenters = async () => {
  const response = await fetch(`${API_BASE_URL}/dashboard/top-presenters`);
  return await response.json();
};

export const getRecentQuestions = async () => {
  const response = await fetch(`${API_BASE_URL}/dashboard/recent-questions`);
  return await response.json();
};

export const getSessionRatings = async () => {
  const response = await fetch(`${API_BASE_URL}/dashboard/session-ratings`);
  return await response.json();
};
