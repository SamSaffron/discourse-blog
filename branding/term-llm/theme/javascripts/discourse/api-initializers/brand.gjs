import { apiInitializer } from "discourse/lib/api";
import CommunityHeader from "../components/community-header";

export default apiInitializer((api) => {
  api.renderInOutlet("above-main-container", CommunityHeader);
});
