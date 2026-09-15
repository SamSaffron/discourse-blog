import BlogDashboard from "../components/blog-dashboard";

export default <template>
  {{#if @model}}<BlogDashboard @model={{@model}} />{{/if}}
</template>
